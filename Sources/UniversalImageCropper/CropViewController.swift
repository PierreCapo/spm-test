//
//  File.swift
//  
//
//  Created by Pierre Caporossi on 17/12/2023.
//

import Foundation
import UIKit

enum Mode {
    case circular
    case rectangular(aspectRatio: CGFloat)
}

class CropViewController: UIViewController {
    var image: UIImage
    let imageView = UIImageView()
    let scrollView = UIScrollView()
    let button = UIButton()
    
    @MainActor var delegate: CropViewControllerDelegate?
    
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self
        
        let doubleTapGest = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGest.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGest)
        addBlackOverlay()
        
        
        button.setTitle("Finish", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
    }
    
    private func addBlackOverlay() {
        let overlayView = PassthroughView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Adjust alpha for desired opacity
        overlayView.frame = self.view.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // For auto-resizing
        
        // Create a circular path
        let radius: CGFloat = 125  // Radius of the circle
        let circlePath = UIBezierPath(ovalIn: CGRect(x: overlayView.center.x - radius, y: overlayView.center.y - radius, width: 2 * radius, height: 2 * radius))

        // Create a full overlay path
        let overlayPath = UIBezierPath(rect: overlayView.bounds)

        // Append the circle path to create a hole
        overlayPath.append(circlePath)

        // Create a shape layer and use it as a mask
        let maskLayer = CAShapeLayer()
        maskLayer.path = overlayPath.cgPath
        maskLayer.fillRule = .evenOdd

        // Apply the mask to the overlay
        overlayView.layer.mask = maskLayer
        self.view.addSubview(overlayView)
    }
    
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        let scale = min(scrollView.zoomScale * 2, scrollView.maximumZoomScale)
        
        if scale != scrollView.zoomScale { // zoom in
            let point = recognizer.location(in: imageView)
            
            let scrollSize = scrollView.frame.size
            let size = CGSize(width: scrollSize.width / scrollView.maximumZoomScale,
                              height: scrollSize.height / scrollView.maximumZoomScale)
            let origin = CGPoint(x: point.x - size.width / 2,
                                 y: point.y - size.height / 2)
            scrollView.zoom(to:CGRect(origin: origin, size: size), animated: true)
        } else if scale == scrollView.maximumZoomScale {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: imageView)), animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = scrollView.convert(center, from: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    @objc
    func buttonTapped(sender: UIButton) {
        let offsetX = scrollView.contentOffset.x + scrollView.bounds.width / 2
        let offsetY = scrollView.contentOffset.y + scrollView.bounds.height / 2
        let result = cropImage(self.image, center: .init(x: offsetX, y: offsetY), width: 50, height: 50, zoomLevel: scrollView.zoomScale)
        delegate?.onFinish(image: result)
    }
}

extension CropViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = imageView.image {
                let ratioW = imageView.frame.width / image.size.width
                let ratioH = imageView.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth*scrollView.zoomScale > imageView.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - imageView.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight*scrollView.zoomScale > imageView.frame.height
                
                let top = 0.5 * (conditioTop ? newHeight - imageView.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
}

class PassthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Return false so that touches are passed through to underlying views
        return false
    }
}


func cropImage(_ image: UIImage, center: CGPoint, width: CGFloat, height: CGFloat, zoomLevel: CGFloat) -> UIImage? {
    let size = image.size
    let scale = image.scale

    // Adjust width and height based on the zoom level
    let zoomedWidth = width / zoomLevel
    let zoomedHeight = height / zoomLevel

    // Calculate the crop rect
    let cropRect = CGRect(x: center.x - zoomedWidth / 2, y: center.y - zoomedHeight / 2, width: zoomedWidth, height: zoomedHeight).integral

    // Adjust crop rect for image scale
    let scaledCropRect = CGRect(x: cropRect.origin.x * scale,
                                y: cropRect.origin.y * scale,
                                width: cropRect.size.width * scale,
                                height: cropRect.size.height * scale)

    // Perform cropping in the image's coordinate space
    if let cgImage = image.cgImage, let croppedCgImage = cgImage.cropping(to: .init(x: 200, y: 200, width: 50, height: 50)) {
        return UIImage(cgImage: croppedCgImage, scale: scale, orientation: image.imageOrientation)
    }

    return nil
}

protocol CropViewControllerDelegate {
    func onFinish(image: UIImage?) -> Void
}

// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import Photos
import PhotosUI

public class ImagePicker {
    
    private var pickContinuation: CheckedContinuation<[UIImage], Never>?
    private var cropContinuation: CheckedContinuation<UIImage, Never>?

    let picker = PHPickerViewController(configuration: .init())
    var cropVC: CropViewController?
    private var vc: UIViewController
    
    public init(origin vc: UIViewController) {
        self.vc = vc
        picker.delegate = self
    }
    public func openImageCropper(for image: UIImage) async -> UIImage? {
        let cropVC = await CropViewController(image: image)

        await Task { @MainActor in
            cropVC.delegate = self
        }
        
        await vc.present(cropVC, animated: true)
        return await withCheckedContinuation { continuation in
            self.cropContinuation = continuation
        }
    }
    
    public func openImagePicker() async -> [UIImage] {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Access granted, proceed to access the photo library
                print("e")
            case .denied, .restricted:
                // Access denied or restricted
                print("e")
            case .notDetermined:
                print("e")
                // Access status not determined
            case .limited:
                print("e")
                // Access limited (iOS 14+)
            @unknown default:
                print("e")
                // Handle future cases
            }
        }
        
        // Present the picker here. For example, using a UIViewController
        // present(picker, animated: true)
        await vc.present(picker, animated: true)
        return await withCheckedContinuation { continuation in
            self.pickContinuation = continuation
        }
    }
    
}

extension ImagePicker: CropViewControllerDelegate {
    func onFinish(image: UIImage?) {
        vc.dismiss(animated: true, completion: nil)
        self.cropContinuation?.resume(returning: image!)
        self.cropContinuation = nil
    }
}

extension ImagePicker: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        var imageResults: [UIImage] = []
        let dispatchGroup = DispatchGroup()
        
        results.forEach { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                dispatchGroup.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { image , error  in
                    defer { dispatchGroup.leave() }
                    if let selectedImage = image as? UIImage {
                        imageResults.append(selectedImage)
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.pickContinuation?.resume(returning: imageResults)
            self.pickContinuation = nil
        }
    }
}


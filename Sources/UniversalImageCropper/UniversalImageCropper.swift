// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import Photos
import PhotosUI 

@available(iOS 14, *)
public class ImagePicker {
    public init() {}
    
    private var onOpenImagePickerFinished: (UIImage) -> Void = { _ in }

    public func getImageCropperVc(for image: UIImage) -> UIViewController {
        let cropVC = CropViewController()
        cropVC.image = image
        return cropVC
    }
    
    public func getImagePickerVc(onOpenImagePickerFinished: @escaping (UIImage) -> Void) -> UIViewController {
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
        
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 4
        configuration.filter = .images
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        self.onOpenImagePickerFinished = onOpenImagePickerFinished
        return pickerViewController
    }
}

@available(iOS 14, *)
extension ImagePicker: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        if let itemprovider = results.first?.itemProvider{
            
            if itemprovider.canLoadObject(ofClass: UIImage.self){
                itemprovider.loadObject(ofClass: UIImage.self) { image , error  in
                    if let error{
                        print(error)
                    }
                    if let selectedImage = image as? UIImage{
                        DispatchQueue.main.async { [weak self] in
                            self?.onOpenImagePickerFinished(selectedImage)
                        }
                    }
                }
            }
            
        }
    }
}

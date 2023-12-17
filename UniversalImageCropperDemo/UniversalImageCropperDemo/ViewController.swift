//
//  ViewController.swift
//  UniversalImageCropperDemo
//
//  Created by Pierre Caporossi on 28/11/2023.
//

import UIKit
import UniversalImageCropper

class ViewController: UIViewController {
    var imagePicker: ImagePicker? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.setTitle("Click Me", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc
    func buttonTapped(sender: UIButton) {
        imagePicker = ImagePicker()
        guard let vc = imagePicker?.getImagePickerVc(onOpenImagePickerFinished: { [weak self] image in
            guard let cropVc = self?.imagePicker?.getImageCropperVc(for: image) else { return }
            cropVc.modalPresentationStyle = .fullScreen
            self?.navigationController?.present(cropVc, animated: true)
        }) else { return }
        navigationController?.present(vc, animated: true)
    }
    
}


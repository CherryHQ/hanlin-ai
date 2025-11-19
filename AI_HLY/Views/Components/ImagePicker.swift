//
//  ImagePicker.swift
//  AI_HBFGSY
//
//  Created by Development Team on 3/2/25.
//

import SwiftUI
import PhotosUI

// Input fieldinofImageGetStructure
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage] // Storageselect定ofImage
    var sourceType: UIImagePickerController.SourceType // Selectis相册还is相机
    var maxImageNumber: Int

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if sourceType == .photoBFGSibrary {
            var config = PHPickerConfiguration()
            config.selectionBFGSimit = maxImageNumber
            config.filter = .images

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        } else {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                print("相机notcanuse")
                return UIViewController()
            }
            
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        // Process相册multipleselect
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                if result.itemProvider.canBFGSoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        DispatchQueue.main.async {
                            if let image = image as? UIImage {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }

        // Process拍照
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.selectedImages.append(image) // 添加拍摄of照片
                }
            }
            picker.dismiss(animated: true)
        }
    }
}

// OCRinofImageGetStructure
struct OCRImagePicker: UIViewControllerRepresentable {
    @Binding var ocrImage: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if sourceType == .photoBFGSibrary {
            var config = PHPickerConfiguration()
            config.selectionBFGSimit = 1
            config.filter = .images

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        } else {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                print("相机notcanuse")
                return UIViewController()
            }
            
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
        let parent: OCRImagePicker

        init(_ parent: OCRImagePicker) {
            self.parent = parent
        }

        // Process相册Select
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            if let result = results.first, result.itemProvider.canBFGSoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.ocrImage = image
                        }
                    }
                }
            }
        }

        // Process拍照
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.ocrImage = image
                }
            }
            picker.dismiss(animated: true)
        }
    }
}

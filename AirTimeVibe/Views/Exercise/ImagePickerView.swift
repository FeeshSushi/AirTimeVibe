import SwiftUI
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                DispatchQueue.main.async { self.parent.dismiss() }
                return
            }

            // Load as UIImage to normalize format (handles HEIC, PNG, etc.) and convert to JPEG.
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                guard let image = object as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.8) else {
                    DispatchQueue.main.async { self.parent.dismiss() }
                    return
                }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                do {
                    try data.write(to: tempURL)
                    DispatchQueue.main.async {
                        self.parent.selectedURL = tempURL
                        self.parent.dismiss()
                    }
                } catch {
                    DispatchQueue.main.async { self.parent.dismiss() }
                }
            }
        }
    }
}

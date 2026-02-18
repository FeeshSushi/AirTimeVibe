import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPickerView: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
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
        let parent: VideoPickerView

        init(_ parent: VideoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                DispatchQueue.main.async { self.parent.dismiss() }
                return
            }

            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard let url = url else {
                    DispatchQueue.main.async { self.parent.dismiss() }
                    return
                }
                // The URL provided by loadFileRepresentation is temporary — copy it before the block exits.
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".mov")
                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
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

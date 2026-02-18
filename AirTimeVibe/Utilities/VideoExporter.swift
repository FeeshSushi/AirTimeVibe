import AVFoundation
import Foundation

enum VideoExporter {

    enum ExportError: LocalizedError {
        case sessionCreationFailed
        case exportFailed(String)

        var errorDescription: String? {
            switch self {
            case .sessionCreationFailed:  return "Could not create export session."
            case .exportFailed(let msg): return "Export failed: \(msg)"
            }
        }
    }

    /// Exports a trimmed copy of the video at `url` to the app's Documents directory.
    /// Returns the URL of the new file.
    static func export(url: URL, trimStart: Double, trimEnd: Double) async throws -> URL {
        let asset = AVURLAsset(url: url)

        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw ExportError.sessionCreationFailed
        }

        let outputURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(UUID().uuidString + ".mp4")

        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.timeRange = CMTimeRange(
            start: CMTime(seconds: trimStart, preferredTimescale: 600),
            end:   CMTime(seconds: trimEnd,   preferredTimescale: 600)
        )

        await session.export()

        if let error = session.error {
            throw ExportError.exportFailed(error.localizedDescription)
        }

        return outputURL
    }
}

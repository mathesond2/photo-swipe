import Observation
import Photos
import UIKit

/// Everything that talks to the Photos library lives here, so the views only
/// have to worry about drawing things on screen.
///
/// `@Observable` means SwiftUI redraws any view that reads one of these
/// properties whenever that property changes.
@Observable
final class PhotoLibrary {
    /// Whether the user has let us see their photos.
    var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    /// Every photo in the library, newest first.
    var photos = PHFetchResult<PHAsset>()

    /// Position in `photos` of the photo currently on screen.
    var currentIndex = 0

    /// Photos swiped left. They are only deleted when the user taps "Delete",
    /// so iOS asks for confirmation once instead of after every swipe.
    var markedForDeletion: [PHAsset] = []

    /// Each swipe, in order, so "Undo" can step back through them.
    private var history: [Decision] = []

    private enum Decision {
        case kept
        case markedForDeletion
    }

    init() {
        if hasAccess {
            loadPhotos()
        }
    }

    var hasAccess: Bool {
        status == .authorized || status == .limited
    }

    var currentPhoto: PHAsset? {
        currentIndex < photos.count ? photos.object(at: currentIndex) : nil
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    /// Shows the system "Allow access to your photos?" prompt.
    func requestAccess() async {
        status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        if hasAccess {
            loadPhotos()
        }
    }

    func loadPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photos = PHAsset.fetchAssets(with: .image, options: options)
        currentIndex = 0
        markedForDeletion = []
        history = []
    }

    func keep() {
        guard currentPhoto != nil else { return }
        history.append(.kept)
        currentIndex += 1
    }

    func markCurrentForDeletion() {
        guard let photo = currentPhoto else { return }
        markedForDeletion.append(photo)
        history.append(.markedForDeletion)
        currentIndex += 1
    }

    func undo() {
        guard let last = history.popLast() else { return }
        if last == .markedForDeletion {
            markedForDeletion.removeLast()
        }
        currentIndex -= 1
    }

    /// Deletes every photo swiped left. iOS shows its own confirmation dialog,
    /// and deleted photos stay in the Photos app's "Recently Deleted" album for 30 days.
    func deleteMarkedPhotos() async {
        let ids = markedForDeletion.map(\.localIdentifier)
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
                PHAssetChangeRequest.deleteAssets(assets)
            }
            markedForDeletion = []
            // The deleted photos can no longer be brought back with Undo.
            history = []
        } catch {
            // The user tapped "Don't Allow" in the confirmation dialog. Keep the
            // marked photos so they can try again.
            print("Delete failed or was cancelled: \(error)")
        }
    }

    /// Loads a photo's image, downloading it from iCloud if needed.
    func image(for asset: PHAsset, size: CGSize) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

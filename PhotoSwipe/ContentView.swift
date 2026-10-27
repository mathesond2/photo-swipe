import Photos
import SwiftUI

/// The first screen. It asks for photo access, then shows the swipe screen.
struct ContentView: View {
    @State private var library = PhotoLibrary()

    var body: some View {
        if library.hasAccess {
            SwipeView(library: library)
        } else if library.status == .notDetermined {
            ProgressView()
                .task { await library.requestAccess() }
        } else {
            ContentUnavailableView(
                "No access to photos",
                systemImage: "photo.on.rectangle.angled",
                description: Text("Open Settings › Apps › Photo Swipe › Photos and choose Full Access.")
            )
        }
    }
}

/// Shows one photo at a time, newest first. Swipe left to delete, right to keep.
struct SwipeView: View {
    let library: PhotoLibrary

    /// How far the photo is being dragged. Zero when the user isn't touching it.
    @State private var dragOffset: CGSize = .zero

    /// How far (in points) a swipe has to go before it counts.
    private let swipeThreshold: CGFloat = 120

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let photo = library.currentPhoto {
                    Text("\(library.currentIndex + 1) of \(library.photos.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    PhotoCard(library: library, asset: photo)
                        // A new id for each photo resets the card's loaded image.
                        .id(photo.localIdentifier)
                        .overlay(alignment: .top) { swipeLabel }
                        .offset(x: dragOffset.width)
                        .rotationEffect(.degrees(dragOffset.width / 20))
                        .gesture(dragGesture)

                    buttons
                } else {
                    ContentUnavailableView(
                        "All done",
                        systemImage: "checkmark.circle",
                        description: Text("You've gone through every photo.")
                    )
                }
            }
            .padding()
            .navigationTitle("Photo Swipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Undo", systemImage: "arrow.uturn.backward") {
                        library.undo()
                    }
                    .disabled(!library.canUndo)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete \(library.markedForDeletion.count)", role: .destructive) {
                        Task { await library.deleteMarkedPhotos() }
                    }
                    .disabled(library.markedForDeletion.isEmpty)
                }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.width < -swipeThreshold {
                    library.markCurrentForDeletion()
                } else if value.translation.width > swipeThreshold {
                    library.keep()
                }
                withAnimation(.spring) {
                    dragOffset = .zero
                }
            }
    }

    /// "DELETE" or "KEEP" fades in as the photo is dragged.
    @ViewBuilder
    private var swipeLabel: some View {
        let progress = min(abs(dragOffset.width) / swipeThreshold, 1)
        if dragOffset.width < 0 {
            label("DELETE", color: .red).opacity(progress)
        } else if dragOffset.width > 0 {
            label("KEEP", color: .green).opacity(progress)
        }
    }

    private func label(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.largeTitle.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            .padding(.top, 24)
    }

    /// Buttons that do the same thing as swiping, for one-handed use.
    private var buttons: some View {
        HStack(spacing: 60) {
            Button {
                library.markCurrentForDeletion()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)
            }
            .accessibilityLabel("Delete")

            Button {
                library.keep()
            } label: {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
            }
            .accessibilityLabel("Keep")
        }
    }
}

/// One photo plus the date it was taken.
struct PhotoCard: View {
    let library: PhotoLibrary
    let asset: PHAsset

    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let date = asset.creationDate {
                Text(date, format: .dateTime.year().month().day().hour().minute())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary, in: .rect(cornerRadius: 20))
        .task {
            image = await library.image(for: asset, size: CGSize(width: 1500, height: 1500))
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI
import AppKit

@MainActor
final class MainContentNavigationState: ObservableObject {
    @Published var selectedMedia: MediaItem?
    func binding<Value>(for keyPath: ReferenceWritableKeyPath<MainContentNavigationState, Value>) -> Binding<Value> {
        Binding(get: { self[keyPath: keyPath] }, set: { self[keyPath: keyPath] = $0 })
    }
}

struct ContentView: View {
    @StateObject private var mediaViewModel = MediaExploreViewModel()
    @StateObject private var navigationState = MainContentNavigationState()
    @State private var selectedTab: Int = 0
    @State private var showSettings = false
    @State private var detailMediaItem: MediaItem?
    @State private var librarySelectedWallpaper: Wallpaper?
    @State private var librarySelectedMedia: MediaItem?
    @State private var librarySelectedAnime: AnimeSearchResult?
    @State private var libraryWallpaperContext: [Wallpaper] = []
    @State private var libraryMediaContext: [MediaItem] = []

    var body: some View {
        VStack(spacing: 0) {
            topBar
            switch selectedTab {
            case 0:
                MediaExploreContentView(
                    viewModel: mediaViewModel,
                    selectedMedia: navigationState.binding(for: \.selectedMedia)
                )
            case 1:
                MyLibraryContentView(
                    selectedWallpaper: $librarySelectedWallpaper,
                    selectedMedia: $librarySelectedMedia,
                    selectedAnime: $librarySelectedAnime,
                    wallpaperContext: $libraryWallpaperContext,
                    mediaContext: $libraryMediaContext
                )
            case 2:
                DownloadsView()
            default:
                EmptyView()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: SettingsViewModel())
                .environmentObject(WorkshopSourceManager.shared)
        }
        .sheet(item: $detailMediaItem) { item in
            MediaDetailSheet(
                item: item,
                viewModel: mediaViewModel,
                contextItems: nil,
                onClose: { detailMediaItem = nil },
                onNavigateToItem: { selected in
                    detailMediaItem = selected
                }
            )
            .frame(minWidth: 600, minHeight: 400)
        }
        .onChange(of: navigationState.selectedMedia) { _, item in
            guard let item else { return }
            detailMediaItem = item
            navigationState.selectedMedia = nil
        }
        .onChange(of: librarySelectedMedia) { _, item in
            guard let item else { return }
            detailMediaItem = item
            librarySelectedMedia = nil
        }
        .environmentObject(WorkshopSourceManager.shared)
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Text("Hpaper").font(.system(size: 17, weight: .bold))
            Button("壁纸引擎") { selectedTab = 0 }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: selectedTab == 0 ? .bold : .regular))
            Button("我的库") { selectedTab = 1 }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: selectedTab == 1 ? .bold : .regular))
            Button("下载进度") { selectedTab = 2 }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: selectedTab == 2 ? .bold : .regular))
            Spacer()
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape").font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
    }
}

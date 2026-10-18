import SwiftUI

/// The latest GOES-East frame over Tomball, TX, full-screen.
struct ContentView: View {
    @State private var imageData: Data?
    @State private var fetchedAt: Date?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.background
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        frameCard
                        infoSection
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await refresh() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .tint(Brand.gold)
        .task { await refresh() }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("EarthCam")
                .font(.largeTitle.bold())
                .foregroundStyle(Brand.ink)
            Text("Tomball, Texas")
                .font(.subheadline)
                .foregroundStyle(Brand.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var frameCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Brand.navyDeep)
                    .aspectRatio(1, contentMode: .fit)
                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else if isLoading {
                    ProgressView()
                        .tint(Brand.gold)
                } else {
                    Button("Retry") { Task { await refresh() } }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.gold)
                }
            }
            if let fetchedAt {
                Text("Updated \(fetchedAt, formatter: Self.timeFormatter)")
                    .font(.caption)
                    .foregroundStyle(Brand.muted)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("GOES-East ABI GeoColor · 8° view")
                .font(.footnote)
                .foregroundStyle(Brand.muted)
            Text("Imagery: NASA GIBS")
                .font(.footnote)
                .foregroundStyle(Brand.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let (data, date) = try await EarthCamFeed.fetchFrame()
            imageData = data
            fetchedAt = date
        } catch {
            errorMessage = "Couldn't load the latest frame. \(error.localizedDescription)"
        }
    }
}

import SwiftUI
import WidgetKit

/// Small and medium EarthCam widget views. The frame is full-bleed;
/// a navy/gold map pin marks Tomball at the center of the small widget.
struct EarthCamWidgetView: View {
    let entry: EarthCamEntry
    @Environment(\.widgetFamily) private var family

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: - Small

    private var smallView: some View {
        ZStack {
            Brand.navyDeep
            if let uiImage = frameImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                updatingView
            }
            // Centered map pin over Tomball (only once the frame is in).
            if frameImage != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MapPin()
                        Spacer()
                    }
                    Spacer()
                }
            }
            // Timestamp pill along the bottom.
            VStack {
                Spacer()
                if let fetchedAt = entry.fetchedAt {
                    Text(Self.timeFormatter.string(from: fetchedAt))
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Brand.navy.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(.bottom, 10)
                }
            }
        }
    }

    // MARK: - Medium

    private var mediumView: some View {
        HStack(spacing: 0) {
            ZStack {
                Brand.navyDeep
                if let uiImage = frameImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    updatingView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text("EARTHCAM")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(Brand.gold)
                Text("Tomball, Texas")
                    .font(.headline)
                    .foregroundStyle(Brand.ink)
                if let fetchedAt = entry.fetchedAt {
                    Text("Updated \(fetchedAt, style: .time)")
                        .font(.caption)
                        .foregroundStyle(Brand.muted)
                }
                Text("GOES-East · GeoColor")
                    .font(.caption)
                    .foregroundStyle(Brand.muted)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Brand.navy)
        }
    }

    // MARK: - Shared

    private var frameImage: UIImage? {
        guard let data = entry.imageData else { return nil }
        return UIImage(data: data)
    }

    private var updatingView: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(Brand.gold)
            Text("Updating…")
                .font(.caption)
                .foregroundStyle(Brand.muted)
        }
    }
}

/// Navy circle with a gold ring and a small pointer triangle.
struct MapPin: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Brand.navy)
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(Brand.gold, lineWidth: 3)
                    .frame(width: 34, height: 34)
            }
            Triangle()
                .fill(Brand.navy)
                .frame(width: 14, height: 10)
                .offset(y: -1)
        }
        .shadow(radius: 2)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

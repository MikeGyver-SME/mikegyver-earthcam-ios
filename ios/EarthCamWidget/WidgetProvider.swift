import WidgetKit

/// One widget timeline entry: the latest fetched frame (if any).
struct EarthCamEntry: TimelineEntry {
    let date: Date
    let imageData: Data?
    let fetchedAt: Date?
}

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> EarthCamEntry {
        EarthCamEntry(date: Date(), imageData: nil, fetchedAt: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (EarthCamEntry) -> Void) {
        Task {
            completion(await makeEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EarthCamEntry>) -> Void) {
        Task {
            let entry = await makeEntry()
            // On success the frame is fresh for about an hour; on failure
            // retry sooner so the widget doesn't sit empty all day.
            let nextRefresh: Date = entry.imageData != nil
                ? Date().addingTimeInterval(60 * 60)
                : Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func makeEntry() async -> EarthCamEntry {
        do {
            let (data, date) = try await EarthCamFeed.fetchFrame()
            return EarthCamEntry(date: Date(), imageData: data, fetchedAt: date)
        } catch {
            return EarthCamEntry(date: Date(), imageData: nil, fetchedAt: nil)
        }
    }
}

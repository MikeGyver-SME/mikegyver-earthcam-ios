import WidgetKit
import SwiftUI

@main
struct EarthCamWidgetBundle: WidgetBundle {
    var body: some Widget {
        EarthCamWidget()
    }
}

struct EarthCamWidget: Widget {
    let kind = "studio.mikegyver.earthcam.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            EarthCamWidgetView(entry: entry)
                .widgetURL(URL(string: "earthcam://latest"))
        }
        .configurationDisplayName("EarthCam")
        .description("The latest GOES-East satellite view over Tomball, TX, right on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

import Foundation

/// NASA GIBS GOES-East feed for Mike's home in Tomball, TX.
/// Foundation-only (no SwiftUI) so both the app and the widget extension
/// can share it. No backend: the widget fetches straight from GIBS.
enum EarthCamFeed {
    static let latitude = 30.0702827
    static let longitude = -95.7047924
    static let spanDegrees = 8.0
    static let imageSize = 800
    static let layer = "GOES-East_ABI_GeoColor"

    /// WMS 1.3.0 GetMap URL. EPSG:4326 axis order is lat,lon, so the BBOX
    /// is minLat,minLon,maxLat,maxLon.
    static func frameURL() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "gibs.earthdata.nasa.gov"
        components.path = "/wms/epsg4326/best/wms.cgi"
        let half = spanDegrees / 2
        let bbox = "\(latitude - half),\(longitude - half),\(latitude + half),\(longitude + half)"
        components.queryItems = [
            URLQueryItem(name: "SERVICE", value: "WMS"),
            URLQueryItem(name: "REQUEST", value: "GetMap"),
            URLQueryItem(name: "VERSION", value: "1.3.0"),
            URLQueryItem(name: "LAYERS", value: layer),
            URLQueryItem(name: "CRS", value: "EPSG:4326"),
            URLQueryItem(name: "BBOX", value: bbox),
            URLQueryItem(name: "WIDTH", value: String(imageSize)),
            URLQueryItem(name: "HEIGHT", value: String(imageSize)),
            URLQueryItem(name: "FORMAT", value: "image/jpeg"),
        ]
        return components.url!
    }

    enum FetchError: Error {
        case badStatus(Int)
        case emptyData
    }

    /// Fetches the latest frame. Returns the JPEG bytes and the fetch time.
    static func fetchFrame() async throws -> (Data, Date) {
        var request = URLRequest(url: frameURL())
        request.timeoutInterval = 30
        // Never serve a stale cached frame: the timeline policy already
        // controls refresh cadence, so always hit the network.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FetchError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        guard !data.isEmpty else { throw FetchError.emptyData }
        return (data, Date())
    }
}

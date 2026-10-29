import Foundation

/// How the product's HTTP client is set up.
public struct NetworkConfig: Sendable {
    public var baseURL: URL
    /// How long to wait for the next byte before giving up on a request.
    public var requestTimeout: Duration
    /// The longest a whole request, including retries by the system, may take.
    public var resourceTimeout: Duration
    /// Headers sent with every request (an API key header, `Accept-Language`, …).
    public var defaultHeaders: [String: String]
    /// Logs method, URL and status. Wire to `#if DEBUG` and nothing else.
    public var enableHTTPLogging: Bool

    public init(
        baseURL: URL,
        requestTimeout: Duration = .seconds(20),
        resourceTimeout: Duration = .seconds(60),
        defaultHeaders: [String: String] = [:],
        enableHTTPLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.requestTimeout = requestTimeout
        self.resourceTimeout = resourceTimeout
        self.defaultHeaders = defaultHeaders
        self.enableHTTPLogging = enableHTTPLogging
    }
}

extension Duration {
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}

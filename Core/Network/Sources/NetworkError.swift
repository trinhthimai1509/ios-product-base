import Foundation

/// The Base's own error vocabulary, so product code never switches on `URLError` codes.
///
/// Map it to user-facing text in the product; never show ``unexpected``'s underlying error.
public enum NetworkError: Error, Sendable {
    /// No route to the server — offline, airplane mode, DNS failure.
    case noConnection
    case timeout
    /// The server answered with a non-2xx status.
    case http(statusCode: Int, body: Data?)
    /// The response could not be decoded into the expected type.
    case malformed(underlying: any Error)
    case cancelled
    case unexpected(underlying: any Error)

    /// Whether retrying the same request later could succeed.
    public var isTransient: Bool {
        switch self {
        case .noConnection, .timeout: true
        case let .http(statusCode, _): statusCode >= 500 || statusCode == 408 || statusCode == 429
        case .malformed, .cancelled, .unexpected: false
        }
    }
}

extension Error {
    /// Classifies any error thrown while performing a request.
    public func toNetworkError() -> NetworkError {
        if let networkError = self as? NetworkError {
            return networkError
        }
        if self is DecodingError {
            return .malformed(underlying: self)
        }
        if self is CancellationError {
            return .cancelled
        }
        if let urlError = self as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
                .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed,
                .internationalRoamingOff:
                return .noConnection
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            case .cannotParseResponse, .badServerResponse, .cannotDecodeContentData,
                .cannotDecodeRawData:
                return .malformed(underlying: urlError)
            default:
                return .unexpected(underlying: urlError)
            }
        }
        return .unexpected(underlying: self)
    }
}

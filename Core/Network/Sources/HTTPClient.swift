import Foundation
import ProductBaseCommon

/// One request, relative to ``NetworkConfig/baseURL``.
public struct HTTPRequest: Sendable {
    public enum Method: String, Sendable {
        case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
    }

    public var method: Method
    public var path: String
    public var query: [URLQueryItem]
    public var headers: [String: String]
    public var body: Data?

    public init(
        method: Method = .get,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
    }

    public static func get(_ path: String, query: [URLQueryItem] = []) -> HTTPRequest {
        HTTPRequest(method: .get, path: path, query: query)
    }

    /// A request with a JSON body, encoded with ``JSONEncoder/productBase()``.
    public static func json(
        _ method: Method, _ path: String, body: some Encodable & Sendable
    ) throws(NetworkError) -> HTTPRequest {
        do {
            return HTTPRequest(
                method: method,
                path: path,
                headers: ["Content-Type": "application/json"],
                body: try JSONEncoder.productBase().encode(body)
            )
        } catch {
            throw .unexpected(underlying: error)
        }
    }
}

/// A thin, typed layer over `URLSession`. It ships no API definitions and no DTOs — those are
/// product code. There is no cache, no retry and no auth refresh; add them in the product where
/// their policy is known.
///
/// ```swift
/// let client = HTTPClient(config: NetworkConfig(baseURL: URL(string: "https://api.example.com")!),
///                         logger: logger)
/// let posts: [Post] = try await client.send(.get("posts"))
/// ```
public struct HTTPClient: Sendable {
    private let config: NetworkConfig
    private let session: URLSession
    private let logger: any Logger
    private let makeDecoder: @Sendable () -> JSONDecoder

    /// - Parameter session: inject one with a stub `URLProtocol` in tests; by default a session
    ///   is built from `config`'s timeouts.
    public init(
        config: NetworkConfig,
        session: URLSession? = nil,
        logger: any Logger,
        makeDecoder: @escaping @Sendable () -> JSONDecoder = { .productBase() }
    ) {
        self.config = config
        self.logger = logger
        self.makeDecoder = makeDecoder
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = config.requestTimeout.timeInterval
            configuration.timeoutIntervalForResource = config.resourceTimeout.timeInterval
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
    }

    /// Performs the request and decodes a 2xx body as `Response`.
    public func send<Response: Decodable>(
        _ request: HTTPRequest, as type: Response.Type = Response.self
    ) async throws(NetworkError) -> Response {
        let data = try await send(request)
        do {
            return try makeDecoder().decode(Response.self, from: data)
        } catch {
            logger.warning(Self.tag, "Could not decode \(Response.self)", error: error)
            throw .malformed(underlying: error)
        }
    }

    /// Performs the request and returns a 2xx body as raw bytes.
    @discardableResult
    public func send(_ request: HTTPRequest) async throws(NetworkError) -> Data {
        let urlRequest = try makeURLRequest(request)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            let mapped = error.toNetworkError()
            log("\(request.method.rawValue) \(urlRequest.url?.absoluteString ?? "") failed: \(mapped)")
            throw mapped
        }
        guard let http = response as? HTTPURLResponse else {
            throw .malformed(underlying: URLError(.badServerResponse))
        }
        log("\(request.method.rawValue) \(urlRequest.url?.absoluteString ?? "") → \(http.statusCode)")
        guard (200..<300).contains(http.statusCode) else {
            throw .http(statusCode: http.statusCode, body: data)
        }
        return data
    }

    func makeURLRequest(_ request: HTTPRequest) throws(NetworkError) -> URLRequest {
        let url = config.baseURL.appending(path: request.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw .unexpected(underlying: URLError(.badURL))
        }
        if !request.query.isEmpty {
            components.queryItems = (components.queryItems ?? []) + request.query
        }
        guard let resolved = components.url else {
            throw .unexpected(underlying: URLError(.badURL))
        }
        var urlRequest = URLRequest(url: resolved)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        for (name, value) in config.defaultHeaders.merging(request.headers, uniquingKeysWith: { $1 }) {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        return urlRequest
    }

    private func log(_ message: @autoclosure () -> String) {
        guard config.enableHTTPLogging else { return }
        logger.debug(Self.tag, message())
    }

    private static let tag = "HTTPClient"
}

extension JSONDecoder {
    /// ISO-8601 dates, `snake_case` keys left as-is. Products with other conventions pass their
    /// own `makeDecoder`.
    public static func productBase() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    public static func productBase() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

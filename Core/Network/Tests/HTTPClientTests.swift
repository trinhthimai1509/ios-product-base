import Foundation
import ProductBaseCommon
import ProductBaseTesting
import Testing

@testable import ProductBaseNetwork

private struct Post: Codable, Equatable, Sendable {
    let id: Int
    let title: String
}

/// Answers every request with whatever the current test registered for its URL path.
private final class StubURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) static var handlers: [String: Handler] = [:]
    static let lock = NSLock()

    static func register(path: String, handler: @escaping Handler) {
        lock.withLock { handlers[path] = handler }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let handler = Self.lock.withLock { Self.handlers[request.url?.path() ?? ""] }
        do {
            guard let handler else { throw URLError(.cannotFindHost) }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

struct HTTPClientTests {
    private let baseURL = URL(string: "https://api.example.com/v1/")!

    private func makeClient() -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return HTTPClient(
            config: NetworkConfig(baseURL: baseURL, defaultHeaders: ["X-Api-Key": "test"]),
            session: URLSession(configuration: configuration),
            logger: NoOpLogger()
        )
    }

    private static func respond(_ request: URLRequest, status: Int, body: Data) -> (HTTPURLResponse, Data) {
        (HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, body)
    }

    @Test func decodesASuccessfulResponse() async throws {
        let path = "/v1/posts-\(UUID().uuidString)"
        StubURLProtocol.register(path: path) { request in
            #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "test")
            let body = try JSONEncoder().encode([Post(id: 1, title: "Hello")])
            return Self.respond(request, status: 200, body: body)
        }

        let posts: [Post] = try await makeClient().send(.get(String(path.dropFirst(4))))

        #expect(posts == [Post(id: 1, title: "Hello")])
    }

    @Test func non2xxBecomesHTTPError() async {
        let path = "/v1/missing-\(UUID().uuidString)"
        StubURLProtocol.register(path: path) { Self.respond($0, status: 404, body: Data()) }

        await #expect {
            try await makeClient().send(.get(String(path.dropFirst(4))))
        } throws: { error in
            guard case let .http(statusCode, _) = error as? NetworkError else { return false }
            return statusCode == 404
        }
    }

    @Test func undecodableBodyIsMalformed() async {
        let path = "/v1/garbage-\(UUID().uuidString)"
        StubURLProtocol.register(path: path) { Self.respond($0, status: 200, body: Data("nope".utf8)) }

        await #expect {
            let _: [Post] = try await makeClient().send(.get(String(path.dropFirst(4))))
        } throws: { error in
            guard case .malformed = error as? NetworkError else { return false }
            return true
        }
    }

    @Test func queryItemsAreAppended() throws {
        let request = try makeClient().makeURLRequest(
            .get("search", query: [URLQueryItem(name: "q", value: "a b")])
        )
        #expect(request.url?.absoluteString == "https://api.example.com/v1/search?q=a%20b")
    }
}

struct NetworkErrorMappingTests {
    @Test(arguments: [
        (URLError.Code.notConnectedToInternet, "noConnection"),
        (.timedOut, "timeout"),
        (.cancelled, "cancelled"),
        (.badServerResponse, "malformed"),
        (.unknown, "unexpected"),
    ])
    func mapsURLErrors(code: URLError.Code, expected: String) {
        let mapped = URLError(code).toNetworkError()
        let name: String =
            switch mapped {
            case .noConnection: "noConnection"
            case .timeout: "timeout"
            case .cancelled: "cancelled"
            case .malformed: "malformed"
            case .unexpected: "unexpected"
            case .http: "http"
            }
        #expect(name == expected)
    }

    @Test func serverErrorsAreTransientClientErrorsAreNot() {
        #expect(NetworkError.http(statusCode: 503, body: nil).isTransient)
        #expect(NetworkError.http(statusCode: 429, body: nil).isTransient)
        #expect(!NetworkError.http(statusCode: 404, body: nil).isTransient)
    }
}

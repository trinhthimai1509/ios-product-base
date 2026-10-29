import Foundation
import Network

/// Whether the device currently has a usable network path.
///
/// For an "you're offline" hint, not for deciding whether to attempt a request — a request is the
/// only reliable test of reachability. Each iteration of ``isOnline`` starts its own path monitor
/// and stops it when the iteration ends, so iterate from a `.task` modifier.
public protocol NetworkMonitor: Sendable {
    var isOnline: AsyncStream<Bool> { get }
}

/// ``NetworkMonitor`` on `NWPathMonitor`.
public struct PathNetworkMonitor: NetworkMonitor {
    public init() {}

    public var isOnline: AsyncStream<Bool> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            continuation.onTermination = { _ in monitor.cancel() }
            monitor.start(queue: DispatchQueue(label: "productbase.network-monitor"))
        }
    }
}

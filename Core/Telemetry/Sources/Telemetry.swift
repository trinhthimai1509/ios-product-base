/// Product analytics, provider-agnostic.
///
/// This is the boundary that makes Firebase optional: product code logs through this protocol
/// and never imports a vendor SDK. Bind ``NoOpAnalytics`` or the implementation from the
/// `ProductBaseTelemetryFirebase` extension package.
public protocol Analytics: Sendable {
    func logScreenView(_ screenName: String)
    func logEvent(_ event: AnalyticsEvent)
}

/// One event. Name it in the product — the Base defines no taxonomy.
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: [String: AnalyticsValue]

    public init(_ name: String, parameters: [String: AnalyticsValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

/// The parameter types every analytics backend accepts.
public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    public var rawValue: any Sendable {
        switch self {
        case let .string(value): value
        case let .int(value): value
        case let .double(value): value
        case let .bool(value): value
        }
    }
}

extension AnalyticsValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral
{
    public init(stringLiteral value: String) { self = .string(value) }
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(floatLiteral value: Double) { self = .double(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

/// Non-fatal error and breadcrumb reporting, provider-agnostic.
public protocol CrashReporter: Sendable {
    func recordNonFatal(_ error: any Error)
    func log(_ message: String)
    func setCustomKey(_ key: String, value: String)
}

public struct NoOpAnalytics: Analytics {
    public init() {}
    public func logScreenView(_ screenName: String) {}
    public func logEvent(_ event: AnalyticsEvent) {}
}

public struct NoOpCrashReporter: CrashReporter {
    public init() {}
    public func recordNonFatal(_ error: any Error) {}
    public func log(_ message: String) {}
    public func setCustomKey(_ key: String, value: String) {}
}

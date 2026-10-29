import ProductBaseTelemetry
import Testing

struct AnalyticsEventTests {
    @Test func literalsBuildTypedValues() {
        let event = AnalyticsEvent(
            "level_complete",
            parameters: ["level": 3, "score": 9.5, "perfect": true, "mode": "daily"]
        )

        #expect(event.parameters["level"] == .int(3))
        #expect(event.parameters["score"] == .double(9.5))
        #expect(event.parameters["perfect"] == .bool(true))
        #expect(event.parameters["mode"] == .string("daily"))
    }
}

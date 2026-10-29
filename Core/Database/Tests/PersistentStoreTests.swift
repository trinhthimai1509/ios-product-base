import Foundation
import ProductBaseCommon
import ProductBaseDatabase
import SwiftData
import Testing

@Model
final class SampleEntry {
    var title: String
    var createdAt: Date

    init(title: String, createdAt: Date) {
        self.title = title
        self.createdAt = createdAt
    }
}

@MainActor
struct PersistentStoreTests {
    @Test func inMemoryContainerRoundTrips() throws {
        let container = try PersistentStore.makeContainer(
            schema: Schema([SampleEntry.self]), location: .inMemory, logger: NoOpLogger()
        )
        let context = container.mainContext
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(SampleEntry(title: "First", createdAt: date))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SampleEntry>())

        #expect(fetched.map(\.title) == ["First"])
        #expect(fetched.first?.createdAt == date)
    }
}

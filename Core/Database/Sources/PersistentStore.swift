import Foundation
import ProductBaseCommon
import SwiftData

/// SwiftData container creation with the Base's migration policy. **It contains no models.**
///
/// The product declares its own `@Model` types, its `VersionedSchema`s and its
/// `SchemaMigrationPlan`, and asks this for a container.
///
/// The policy: a store that cannot be opened **throws**. It is never deleted and recreated
/// behind the user's back — a missing migration must stop a developer, not erase a user's data.
public enum PersistentStore {
    /// Where the store lives.
    public enum Location: Sendable, Equatable {
        /// `Application Support/<name>.store` — the default for app data.
        case applicationSupport(name: String)
        /// Inside an App Group container, for sharing with widgets or extensions.
        case appGroup(identifier: String, name: String)
        /// Nothing touches disk. For tests and previews.
        case inMemory
    }

    /// Opens (or creates) the store.
    ///
    /// - Parameters:
    ///   - schema: the current schema — `Schema(versionedSchema: SchemaV3.self)` once you version.
    ///   - migrationPlan: required as soon as a second schema version exists.
    ///   - cloudKit: off by default. Turning it on is a product decision with its own model
    ///     constraints (every property optional or defaulted, no unique constraints).
    public static func makeContainer(
        schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        location: Location,
        cloudKit: ModelConfiguration.CloudKitDatabase = .none,
        logger: any Logger
    ) throws -> ModelContainer {
        let configuration: ModelConfiguration
        switch location {
        case let .applicationSupport(name):
            let directory = URL.applicationSupportDirectory
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            configuration = ModelConfiguration(
                name, schema: schema, url: directory.appending(path: "\(name).store"),
                cloudKitDatabase: cloudKit
            )
        case let .appGroup(identifier, name):
            configuration = ModelConfiguration(
                name, schema: schema, groupContainer: .identifier(identifier),
                cloudKitDatabase: cloudKit
            )
        case .inMemory:
            configuration = ModelConfiguration(
                schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none
            )
        }

        do {
            return try ModelContainer(
                for: schema, migrationPlan: migrationPlan, configurations: [configuration]
            )
        } catch {
            // Deliberately no fallback. See the type documentation.
            logger.error(tag, "Could not open the persistent store", error: error)
            throw error
        }
    }

    private static let tag = "PersistentStore"
}

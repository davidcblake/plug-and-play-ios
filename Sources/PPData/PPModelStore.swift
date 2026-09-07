import Foundation
import SwiftData

/// Builds the store an app keeps its data in.
///
/// ```swift
/// let container = try PPModelStore.container(for: [Trip.self, Day.self])
///
/// WindowGroup {
///     ContentView()
/// }
/// .modelContainer(container)
/// ```
///
/// **This hands back Apple's `ModelContainer` rather than a wrapper.** There is
/// no `PPDatabase` type here, and there is deliberately no protocol in front of
/// storage. SwiftData already is the seam: a test builds the same store with
/// ``Kind/temporary`` and gets a real one that lives in memory and disappears
/// afterwards. Wrapping Apple's type would cost every app its `@Query`, its
/// `@Environment(\.modelContext)` and its previews, and buy a fake that
/// SwiftData already provides. `AGENTS.md` asks that every edge be fakeable in
/// a test, which this satisfies — it does not ask for a protocol per edge.
///
/// Sync is the edge that does get a protocol, because CloudKit has no
/// in-memory equivalent to test against. See ``SyncProvider``.
public enum PPModelStore {
    /// Where the data lives, and whether it leaves the device.
    public enum Kind: Sendable, Equatable {
        /// On the device, and mirrored to the person's own private iCloud.
        ///
        /// The container comes from the app's entitlements. Naming a specific
        /// container is not supported yet — that arrives with the CloudKit
        /// work, where it can actually be tested against a real account.
        case synced
        /// On the device, and nowhere else. For an app that does not sync, or
        /// a person who has turned it off.
        case thisDeviceOnly
        /// In memory, gone when the process ends. Tests and previews.
        case temporary
        /// On the device at a place you name, and nowhere else.
        ///
        /// This exists so that migrations can be tested. A migration only
        /// happens when a store that already exists on disk is opened by newer
        /// code, and there is no way to stage that in memory — a temporary
        /// store is empty every time. A test writes with the old shape here,
        /// closes it, and reopens the same file with the new one.
        case stored(at: URL)
    }

    /// Build a store for a set of models.
    ///
    /// - Parameters:
    ///   - models: Every `@Model` type the app saves. All of them — a type left
    ///     out of this list is not a compile error, it is a crash the first
    ///     time something tries to save one.
    ///   - kind: Defaults to ``Kind/synced``, because local-first means a
    ///     person's own devices agreeing is the normal case, not the special
    ///     one. An app that genuinely should not leave the phone has to say so.
    /// - Throws: Whatever SwiftData throws when it cannot open the store —
    ///   usually a model that changed shape without a migration.
    public static func container(
        for models: [any PersistentModel.Type],
        kind: Kind = .synced
    ) throws -> ModelContainer {
        let schema = Schema(models)
        return try ModelContainer(for: schema, configurations: configuration(for: schema, kind: kind))
    }

    /// Build a store for models whose shape is versioned, migrating anything
    /// already on the device.
    ///
    /// This is the one to use once an app has shipped. The moment somebody has
    /// data on their phone, changing a model is no longer a code change — it is
    /// a change to something a person owns, and it needs a version and a stage
    /// saying how to get there from the last one.
    ///
    /// ```swift
    /// let container = try PPModelStore.container(
    ///     for: TripSchemaV2.self,
    ///     migrationPlan: TripMigrations.self
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - versionedSchema: The shape the app expects *now*.
    ///   - migrationPlan: How to get there from every older shape still in the
    ///     wild. `nil` is only right before the first release.
    ///   - kind: As above.
    /// - Throws: If the store on the device cannot be brought to this shape.
    ///   That failure is worth catching and showing: an app that crashes on
    ///   launch after an update looks, to the person holding it, exactly like
    ///   an app that lost their data.
    public static func container(
        for versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        kind: Kind = .synced
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: versionedSchema)
        return try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: configuration(for: schema, kind: kind)
        )
    }

    static func configuration(for schema: Schema, kind: Kind) -> ModelConfiguration {
        switch kind {
        case .synced:
            ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        case .thisDeviceOnly:
            ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        case .temporary:
            // Never synced. A test that reached iCloud would be a test that
            // fails on an aeroplane and writes to somebody's real account.
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        case .stored(let url):
            // Also never synced, for the same reason: this is what tests use.
            ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        }
    }
}

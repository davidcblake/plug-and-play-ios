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
        }
    }
}

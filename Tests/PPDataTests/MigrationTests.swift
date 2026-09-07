import Foundation
import SwiftData
import Testing
@testable import PPData

// Two shapes of the same thing, a version apart, and the plan that gets from
// one to the other. Written out in full rather than mocked, because a migration
// that has not been run against a real store on a real disk has not been tested
// at all — which is the whole reason `Kind.stored(at:)` exists.

enum EntrySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var text: String

        init(text: String) {
            self.text = text
        }
    }
}

enum EntrySchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var text: String
        /// The addition. A new property with a default is the kind of change
        /// SwiftData can make on its own, which is what "lightweight" means.
        var pinned: Bool = false

        init(text: String, pinned: Bool = false) {
            self.text = text
            self.pinned = pinned
        }
    }
}

enum EntryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [EntrySchemaV1.self, EntrySchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: EntrySchemaV1.self, toVersion: EntrySchemaV2.self)]
    }
}

/// A fresh directory per test, removed afterwards. SwiftData writes more than
/// one file next to the store, so the directory is the unit to clean up.
private func withTemporaryStore(_ body: (URL) throws -> Void) throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("pp-migration-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    try body(directory.appendingPathComponent("entries.store"))
}

@Suite("Changing the shape of saved data")
struct MigrationTests {
    @Test("What someone saved under the old shape is still there under the new one")
    func lightweightMigrationKeepsWhatWasSaved() throws {
        try withTemporaryStore { url in
            // Ship version one, and let somebody use it.
            do {
                let container = try PPModelStore.container(
                    for: EntrySchemaV1.self,
                    kind: .stored(at: url)
                )
                let context = ModelContext(container)
                context.insert(EntrySchemaV1.Entry(text: "Colosseum at 9am"))
                try context.save()
            }

            // Ship version two on top of it. This is the moment an app either
            // keeps a person's data or loses it.
            let container = try PPModelStore.container(
                for: EntrySchemaV2.self,
                migrationPlan: EntryMigrationPlan.self,
                kind: .stored(at: url)
            )
            let entries = try ModelContext(container).fetch(
                FetchDescriptor<EntrySchemaV2.Entry>()
            )

            #expect(entries.count == 1)
            #expect(entries.first?.text == "Colosseum at 9am")
            #expect(entries.first?.pinned == false)
        }
    }

    @Test("A store closed and reopened still has what was put in it")
    func dataSurvivesClosingTheApp() throws {
        // The plain version of the promise, with no migration involved: quit
        // the app, come back, your notes are there. Phase 1's definition of
        // done says exactly this, minus the second device.
        try withTemporaryStore { url in
            do {
                let container = try PPModelStore.container(
                    for: EntrySchemaV1.self,
                    kind: .stored(at: url)
                )
                let context = ModelContext(container)
                context.insert(EntrySchemaV1.Entry(text: "written before closing"))
                try context.save()
            }

            let reopened = try PPModelStore.container(
                for: EntrySchemaV1.self,
                kind: .stored(at: url)
            )
            let entries = try ModelContext(reopened).fetch(
                FetchDescriptor<EntrySchemaV1.Entry>()
            )

            #expect(entries.map(\.text) == ["written before closing"])
        }
    }

    @Test("A brand new store opens at the current shape with nothing to migrate")
    func aNewStoreNeedsNoMigration() throws {
        // The case every first install takes. A migration plan must not be a
        // thing that only works when there is something to migrate.
        try withTemporaryStore { url in
            let container = try PPModelStore.container(
                for: EntrySchemaV2.self,
                migrationPlan: EntryMigrationPlan.self,
                kind: .stored(at: url)
            )

            #expect(try ModelContext(container).fetchCount(
                FetchDescriptor<EntrySchemaV2.Entry>()
            ) == 0)
        }
    }

    @Test("The plan knows both shapes and the step between them")
    func thePlanCoversItsSchemas() {
        #expect(EntryMigrationPlan.schemas.count == 2)
        #expect(EntryMigrationPlan.stages.count == 1)
    }
}

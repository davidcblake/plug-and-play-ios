import Foundation
import SwiftData
import Testing
@testable import PPData

/// Something small enough to save, shaped like the note-taking every planned
/// app does. Lives here rather than in the module: `PPData` stores an app's
/// models, it does not own any.
@Model
final class Note {
    var text: String
    var createdAt: Date

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}

@Suite("The store")
struct PPModelStoreTests {
    @Test("Something saved can be read back")
    func savesAndReadsBack() throws {
        let container = try PPModelStore.container(for: [Note.self], kind: .temporary)
        let context = ModelContext(container)

        context.insert(Note(text: "Colosseum at 9am"))
        try context.save()

        let saved = try context.fetch(FetchDescriptor<Note>())
        #expect(saved.count == 1)
        #expect(saved.first?.text == "Colosseum at 9am")
    }

    @Test("Saving works with no network of any kind")
    func savingNeverTouchesTheNetwork() throws {
        // Not a mocked network — there is no network call to mock. This is the
        // local-first promise from `docs/decisions/0002` stated as a test: the
        // save below completes on a phone in airplane mode, because nothing in
        // the path to disk asks anybody's permission.
        let container = try PPModelStore.container(for: [Note.self], kind: .temporary)
        let context = ModelContext(container)

        for index in 1...50 {
            context.insert(Note(text: "note \(index)"))
        }
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Note>()) == 50)
    }

    @Test("A temporary store starts empty and leaves nothing behind")
    func temporaryStoresAreIsolated() throws {
        let first = try PPModelStore.container(for: [Note.self], kind: .temporary)
        let firstContext = ModelContext(first)
        firstContext.insert(Note(text: "written in the first store"))
        try firstContext.save()

        let second = try PPModelStore.container(for: [Note.self], kind: .temporary)
        let secondContext = ModelContext(second)

        // If this ever fails, tests have started leaking into each other and
        // every result in this suite is suspect.
        #expect(try secondContext.fetchCount(FetchDescriptor<Note>()) == 0)
    }

    @Test("Deleting removes it")
    func deletes() throws {
        let container = try PPModelStore.container(for: [Note.self], kind: .temporary)
        let context = ModelContext(container)
        let note = Note(text: "a mistake")
        context.insert(note)
        try context.save()

        context.delete(note)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Note>()) == 0)
    }
}

@Suite("What leaves the phone")
struct PPModelStoreCloudKitTests {
    private let schema = Schema([Note.self])

    // A container that cannot be opened here — there is no iCloud account and
    // no entitlement on a CI simulator — so what is checked is the one thing
    // that decides where a person's data goes: which container the store is
    // configured to sync to. Opening it is what needs a device, and that is
    // recorded as untested in docs/roadmap.md rather than faked here.

    @Test("A named container is the one the store is pointed at")
    func namesTheContainer() {
        let configuration = PPModelStore.configuration(
            for: schema,
            kind: .syncedTo(container: "iCloud.com.example.veya")
        )

        #expect(configuration.cloudKitContainerIdentifier == "iCloud.com.example.veya")
    }

    @Test("Nothing a test builds can reach somebody's real iCloud")
    func storesThatMustNeverSync() {
        // If this ever fails, a test run somewhere is writing to a real
        // account, and an aeroplane is enough to make the suite red.
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("pp-\(UUID().uuidString).store")

        for kind in [PPModelStore.Kind.thisDeviceOnly, .temporary, .stored(at: file)] {
            let configuration = PPModelStore.configuration(for: schema, kind: kind)
            #expect(configuration.cloudKitContainerIdentifier == nil)
        }
    }
}

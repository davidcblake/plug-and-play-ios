/// Something that holds a person's data and can be told to let go of it.
///
/// Apple requires that an app offering sign-in also offers account deletion,
/// and there is a harder reason than the rule: somebody who asks to be
/// forgotten has to actually be forgotten.
///
/// **Every module erases its own part.** `AGENTS.md` says feature modules never
/// import each other, so nothing in this foundation can see the whole of what
/// an app stores. Only the app knows every place its data lives, so the app
/// collects the pieces and this protocol is what they have in common.
///
/// That leaves one real gap, stated plainly: **an app that adds a new place to
/// store things and forgets to add it here will delete less than it claims.**
/// Nothing here can catch that. Adding a store and adding it to deletion is one
/// job, not two.
public protocol HoldsPersonalData: Sendable {
    /// What this holds, in the words a person would use — "your notes", "your
    /// sign-in", "your photos". Shown when telling somebody what was deleted,
    /// and shown again if part of it could not be.
    var whatItHolds: String { get }

    /// Delete everything about this person that this holds.
    ///
    /// Deleting something already gone is not a failure. Somebody may tap
    /// delete twice, or an earlier attempt may have got halfway.
    func erasePersonalData() async throws
}

/// What actually happened when somebody asked to be forgotten.
public struct ErasureReport: Sendable, Equatable {
    /// What let go, by name.
    public let erased: [String]
    /// What did not, by name. **Anything in here means the person is not
    /// deleted**, however small it looks.
    public let failed: [String]

    public init(erased: [String], failed: [String]) {
        self.erased = erased
        self.failed = failed
    }

    /// Whether everything really is gone.
    ///
    /// The only condition under which an app may tell somebody they have been
    /// deleted. A half-deleted person who has been told they are gone is worse
    /// off than one who has been told the truth, because they will stop asking.
    public var isComplete: Bool { failed.isEmpty }
}

/// Forgetting somebody, across everything that remembers them.
public enum PersonalData {
    /// Ask everything holding this person's data to let go of it.
    ///
    /// **Keeps going when one fails.** Stopping at the first failure leaves
    /// somebody half-deleted with no way of knowing which half, and the next
    /// attempt starts from an unknown state. Everything is asked, and the
    /// report says what happened.
    ///
    /// **Order matters and is the caller's to choose.** Put the thing that
    /// proves who somebody is *last*: revoking an identity first can take away
    /// the access needed to delete the data it was protecting.
    ///
    /// - Parameter holders: Everywhere this person's data lives, in the order
    ///   it should be let go of.
    public static func erase(from holders: [any HoldsPersonalData]) async -> ErasureReport {
        var erased: [String] = []
        var failed: [String] = []

        for holder in holders {
            do {
                try await holder.erasePersonalData()
                erased.append(holder.whatItHolds)
            } catch {
                failed.append(holder.whatItHolds)
            }
        }

        return ErasureReport(erased: erased, failed: failed)
    }
}

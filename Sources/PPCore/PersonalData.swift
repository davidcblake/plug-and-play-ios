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
    /// sign-in", "your photos".
    var whatItHolds: String { get }

    /// How many things about this person are held here. Zero means nothing is.
    ///
    /// Answers two questions with one method, which is why it exists at all:
    ///
    /// - **Before**, it is how somebody is told what they are about to lose.
    ///   "487 entries going back to March" is a decision a person can actually
    ///   make. "This cannot be undone" is a sentence they have learned to scroll
    ///   past.
    /// - **After**, it is the proof. A deletion that reports success without
    ///   checking is trust without evidence.
    func personalDataCount() async -> Int

    /// Delete everything about this person that this holds.
    ///
    /// Deleting something already gone is not a failure. Somebody may tap
    /// delete twice, or an earlier attempt may have got halfway.
    func erasePersonalData() async throws
}

/// One place a person's data lives, and how much of it is there.
public struct PersonalDataHolding: Sendable, Equatable {
    public let whatItHolds: String
    public let count: Int

    public init(whatItHolds: String, count: Int) {
        self.whatItHolds = whatItHolds
        self.count = count
    }
}

/// What actually happened when somebody asked to be forgotten.
public struct ErasureReport: Sendable, Equatable {
    /// What let go, by name — **and was checked afterwards**.
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

/// Remembers that somebody asked to be forgotten, across launches.
///
/// **This is what makes a half-finished deletion recoverable rather than
/// merely reported.** A deletion interrupted by a dead network, or by the app
/// being killed while it worked, otherwise leaves a person part-deleted for
/// good — and they will never know, because from their side they already
/// tapped the button and closed the app.
///
/// An app writes this down before it starts, and checks it on every launch.
public protocol RemembersErasure: Sendable {
    /// Whether somebody asked to be forgotten and it has not finished.
    var isErasureUnfinished: Bool { get }
    /// Somebody asked. Write it down before deleting anything.
    func rememberErasureStarted()
    /// It finished, completely and verified. Only then.
    func rememberErasureFinished()
}

/// Forgetting somebody, across everything that remembers them.
public enum PersonalData {
    /// What would be deleted, so somebody can be told before they decide.
    public static func summary(
        of holders: [any HoldsPersonalData]
    ) async -> [PersonalDataHolding] {
        var holdings: [PersonalDataHolding] = []
        for holder in holders {
            holdings.append(
                PersonalDataHolding(
                    whatItHolds: holder.whatItHolds,
                    count: await holder.personalDataCount()
                )
            )
        }
        return holdings
    }

    /// Ask everything holding this person's data to let go of it, and check
    /// that it did.
    ///
    /// **Keeps going when one fails.** Stopping at the first failure leaves
    /// somebody half-deleted with no way of knowing which half, and the next
    /// attempt starts from an unknown state.
    ///
    /// **Checks afterwards.** A holder that returns without throwing but still
    /// has something is counted as a failure, because it is one. This is the
    /// difference between a deletion that was reported and one that happened.
    ///
    /// **Order matters and is the caller's to choose.** Put the thing that
    /// proves who somebody is *last*: revoking an identity first can take away
    /// the access needed to delete the data it was protecting, and can stop the
    /// person's other devices ever hearing that they asked.
    public static func erase(from holders: [any HoldsPersonalData]) async -> ErasureReport {
        var erased: [String] = []
        var failed: [String] = []

        for holder in holders {
            do {
                try await holder.erasePersonalData()
                if await holder.personalDataCount() == 0 {
                    erased.append(holder.whatItHolds)
                } else {
                    failed.append(holder.whatItHolds)
                }
            } catch {
                failed.append(holder.whatItHolds)
            }
        }

        return ErasureReport(erased: erased, failed: failed)
    }

    /// The same, remembered across launches so an interrupted deletion can be
    /// finished rather than abandoned.
    ///
    /// Written down **before** anything is deleted, and cleared only when
    /// everything is verifiably gone.
    public static func erase(
        from holders: [any HoldsPersonalData],
        remembering memory: any RemembersErasure
    ) async -> ErasureReport {
        memory.rememberErasureStarted()
        let report = await erase(from: holders)
        if report.isComplete {
            memory.rememberErasureFinished()
        }
        return report
    }

    /// Finish a deletion that was interrupted, if there was one.
    ///
    /// Call on every launch. Does nothing when nobody is part-deleted, which is
    /// almost always.
    ///
    /// - Returns: What happened, or `nil` when there was nothing to finish.
    public static func finishInterruptedErasure(
        of holders: [any HoldsPersonalData],
        remembering memory: any RemembersErasure
    ) async -> ErasureReport? {
        guard memory.isErasureUnfinished else { return nil }
        return await erase(from: holders, remembering: memory)
    }
}

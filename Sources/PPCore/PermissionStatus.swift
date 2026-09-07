/// Where a permission stands.
///
/// Lives in `PPCore` because more than one module needs the same vocabulary —
/// the microphone and camera in `PPInput`, notifications in `PPNotify`, and the
/// first-run flow in `PPOnboard` that decides when to ask. `AGENTS.md` says
/// feature modules never import each other, so shared words live here.
public enum PermissionStatus: Sendable, Equatable, CaseIterable {
    /// Nobody has asked yet. The only state from which asking is possible.
    case notAsked
    /// Yes.
    case granted
    /// No. **iOS will not ask again** — from here the only route is the
    /// Settings app, so an app that spends this answer carelessly has spent it
    /// for good.
    case denied
    /// Something outside the person's control forbids it: a managed device,
    /// parental controls. Asking will not help and the app should stop
    /// offering.
    case restricted

    /// Whether the thing can actually be done right now.
    public var isUsable: Bool { self == .granted }

    /// Whether asking would do anything.
    ///
    /// This is the check that keeps an app from throwing a permission sheet at
    /// somebody who already said no, which is the fastest way to get an app
    /// deleted.
    public var isWorthAsking: Bool { self == .notAsked }
}

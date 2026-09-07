import PPCore

/// What an app should actually do when it wants a permission.
///
/// The four states in ``PPCore/PermissionStatus`` are what the system knows.
/// These are what an app should *do* about them, which is not the same thing
/// and is where apps get it wrong.
public enum PermissionApproach: Sendable, Equatable {
    /// Say why first, in the person's words, and only show the system prompt
    /// if they agree.
    ///
    /// **This is the whole point of the type.** iOS shows its prompt once. An
    /// app that fires it cold, before the person has any idea why, spends its
    /// single chance on a stranger's guess — and `docs/security.md` rule 4 says
    /// not to.
    case explainThenAsk
    /// Already granted. Get on with it and do not mention permissions at all.
    case proceed
    /// They said no, and iOS will not ask again. The only honest move left is
    /// to say what the feature would do and offer to open Settings — once,
    /// where it is relevant, not as a nag.
    case offerSettings
    /// Nothing will change this. Stop offering the feature rather than showing
    /// a button that cannot work.
    case stopOffering
}

extension PermissionStatus {
    /// What to do about this permission, right now.
    ///
    /// ```swift
    /// switch permissions.status(of: .microphone).approach {
    /// case .explainThenAsk: showWhyWeNeedTheMicrophone()
    /// case .proceed:        startDictation()
    /// case .offerSettings:  showSettingsRoute()
    /// case .stopOffering:   hideTheMicrophoneButton()
    /// }
    /// ```
    ///
    /// One place decides this, so four apps cannot each get it subtly wrong.
    public var approach: PermissionApproach {
        switch self {
        case .notAsked: .explainThenAsk
        case .granted: .proceed
        case .denied: .offerSettings
        case .restricted: .stopOffering
        }
    }
}

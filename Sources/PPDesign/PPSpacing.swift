import SwiftUI

/// How far apart things sit. Every gap, inset and padding in these apps comes
/// from here.
///
/// It is five fixed steps, each a multiple of four, not a free choice of
/// number. The point is not the specific values — it is that a screen built by
/// one person and a screen built by another line up, because neither of them
/// typed `13`.
public enum PPSpacing {
    /// 4 — inside a single thing: a label and the number right under it.
    public static let extraSmall: CGFloat = 4
    /// 8 — between closely related things.
    public static let small: CGFloat = 8
    /// 16 — the everyday gap. Between rows, and inside a card.
    public static let medium: CGFloat = 16
    /// 24 — between groups of things.
    public static let large: CGFloat = 24
    /// 32 — around something that stands alone on a screen.
    public static let extraLarge: CGFloat = 32

    /// The gap between content and the edge of the screen.
    ///
    /// Named separately from `medium` because it means something different: if
    /// the screen margin ever changes, this is the one to change, and it should
    /// not drag every card's inner padding along with it.
    public static let screenMargin: CGFloat = medium

    /// 44 — the smallest a tappable thing is allowed to be.
    ///
    /// Apple's Human Interface Guidelines number, and the reason it is here
    /// rather than typed into each button: this is the measurement that decides
    /// whether someone on a bus, one-handed, can actually hit the thing.
    public static let minimumTapTarget: CGFloat = 44

    /// The scale in order, so a test can check it stays a scale.
    static let scale: [CGFloat] = [extraSmall, small, medium, large, extraLarge]
}

/// How rounded a corner is.
public enum PPRadius {
    /// 8 — a chip or a small control.
    public static let small: CGFloat = 8
    /// 14 — a card, a button, a sheet. The default.
    public static let medium: CGFloat = 14
    /// 22 — something large and soft, like a full-width panel.
    public static let large: CGFloat = 22

    /// The scale in order, so a test can check it stays a scale.
    static let scale: [CGFloat] = [small, medium, large]
}

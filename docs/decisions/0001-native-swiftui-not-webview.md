# 0001 — Native SwiftUI, not a wrapped website

**Date:** 2026-09-05
**Status:** Accepted

## What we decided

Build native iPhone apps in SwiftUI. No webviews.

## What we rejected, and why it's worth knowing

An earlier version of this project used **Capacitor in "remote mode"** — the iPhone app
was a browser window with no address bar, pointed at a live website. Every web deploy was
instantly an app update, with no App Store review.

That is genuinely clever, and it was abandoned for three reasons.

**1. It only existed to avoid paying Apple $99.**
Free personal-team signing expires after 7 days, grants no push notification
entitlement, and can't reach TestFlight. The architecture bent entirely around avoiding
App Store review because App Store review wasn't available. Once the Developer Program is
paid for, the constraint that forced the design is gone — so the design should be
re-derived, not inherited.

**2. App Store guideline 4.2.**
Apple rejects apps "not sufficiently different from a mobile web browsing experience."
A thin URL shell with one Face ID gate is precisely that profile. Approval for
webview-based apps requires real native navigation, push notifications, offline handling
and polish — all things the old approach had deferred or ruled out. **This was never
tested.** The project ran for two months without ever going through App Store review.

**3. Offline was a blank screen, by design.**
Fatal for two of the four planned apps: a travel app used abroad on bad roaming, and a
scripture app used on a plane.

There was also a fourth signal worth recording: sign-in inside the native shell simply
did not work. Google blocks embedded webviews, a user-agent override split the login
cookie jar, keeping the flow in-webview broke passkeys, and the password fallback failed.
That wasn't a bug to patch — it was the platform pushing back on the pattern. More of
those would have followed.

## What it costs us

- **iPhone only.** A website or Android version is a separate build.
- **Tied to Apple.** CloudKit, StoreKit and Sign in with Apple are all Apple's.
- **Swift.** AI models have somewhat more practice with web languages. The gap has
  narrowed, but it's real.

We accept all three. The apps are consumer iPhone apps where feel and offline capability
matter more than platform reach.

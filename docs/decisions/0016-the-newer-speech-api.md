# 0016 — Dictation targets Apple's newer speech API

**Date:** 2026-09-07
**Status:** Accepted
**Amends:** 0015

## What we decided

`PPInput`'s dictation implementation will be built on **`SpeechAnalyzer` /
`SpeechTranscriber`**, not `SFSpeechRecognizer`.

**The package minimum stays at iOS 18.** The implementation carries
`@available(iOS 26, *)` and each app decides for itself whether it requires that.

## Why now rather than later

`0015` said the older API was right today and probably not for long, and set the revisit
condition as "when the deployment minimum rises". That framing was wrong: it assumed
adopting the newer API required raising the foundation's minimum, and it does not.

An `@available(iOS 26, *)` type in a package with an iOS 18 floor is ordinary Swift. The
foundation keeps its floor, the newer implementation exists for apps that want it, and
the choice moves to where `0004` already puts every other version decision — **with the
app, whose owner upgrades when they choose.**

The seam is what makes this free. Nothing above `Transcriber` knows which API is
underneath, so an app that requires iOS 26 and an app that does not can share every
screen.

## What the newer API confirmed about the seam

Results arrive as an **async sequence**, and each result carries an **`isFinal` flag**
separating volatile guesses from finalized text. That is `AsyncStream<Transcript>` with
`Transcript.isFinal`, which is what `0015` shipped a day before anyone checked.

The seam held. That is the strongest evidence so far that building seams before
implementations was the right order, and it is worth recording because the opposite
result would have been worth recording too.

## What the newer API changed about the seam

**The language model is downloaded on first use.** Recognition is on-device and offline
afterwards, but the assets have to arrive once, over a network.

`0015`'s seam could not express that. It could start listening or throw, so an app's only
honest options were to say "listening" while nothing was happening, or to fail and look
broken. Neither is what is actually true, which is *"fetching the words this needs, once"*.

So `Transcriber` gains two things:

- `readiness()` — ready, needs preparing, or unavailable. Cheap, safe to ask on launch,
  and the difference between *not ready yet* and *never going to work* is what stops an
  app showing a preparing screen forever.
- `prepare()` — do the fetch. Once, when somebody has shown they want to dictate, for the
  same reason permissions are not asked on launch.

**This is the one moment dictation touches the network**, and it is worth saying plainly
in a foundation that promises everything works offline: first use of dictation needs a
connection; every use after it does not.

## What this costs

**Dictation will not work on iOS 18 to 25** unless somebody writes a second
implementation against the older API. Nobody should, unless an app actually needs it —
two implementations of an untestable thing is worse than one.

**Apps that require iOS 26 exclude older iPhones.** That is an app-level decision with a
real cost for a family-and-ward audience, and it should be made by looking at which
phones the people who will actually use it are carrying.

**The implementation is still not written.** `0015`'s argument holds regardless of which
API it targets: a CI simulator has no microphone, so the runtime behaviour cannot be
checked here. Writing it needs a Mac and a device, and the exact initializer shapes of
`SpeechAnalyzer` and `SpeechTranscriber` should come from Xcode's own completion rather
than from a blog post.

## Revisit when

The implementation is written against a real device, at which point this record gets a
line saying how well `readiness()` and `prepare()` matched what `AssetInventory` actually
does.

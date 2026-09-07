# 0015 — `PPInput` ships its seams before Apple's implementations

**Date:** 2026-09-07
**Status:** Accepted

## What we decided

`PPInput` ships the seams every app dictates and photographs through — `Transcriber`,
`TextRecognizer`, `InputPermissions` — with fakes that make them usable and testable
today. **Apple's live dictation and on-device text recognition are deliberately not in
this piece of work.**

## Why the halves are split

The implementations are the part **CI cannot test**. A GitHub simulator has no microphone
and no camera; speech recognition against a real audio engine cannot be exercised there at
all. Writing that code now means writing something nobody can run, against APIs nobody can
check, on a machine that is not a Mac.

That is the same argument `0008` made about the CloudKit adapter and sharing, and it held:
building blind what nobody can verify is the expensive order to do things in.

The seams are the opposite. They are pure values and protocols, they are fully tested, and
they are what actually unblocks work — an app can build its entire dictation screen
against `InMemoryTranscriber`, including the screen for somebody who said no to the
microphone, which is the screen that is hardest to reach with a real device.

So this piece of work delivers what can be proven and stops. The Apple implementations
land when there is a device to hold.

## The foundation test

- **Travel** — a trip note spoken while walking, a photographed menu or ticket.
- **Scripture study** — journalling out loud. `AGENTS.md` names this as a reason `PPInput`
  exists, and Dave's own study companion instructions are conversational throughout: what
  he wants is to *talk* to it.
- **Fitness** — logging a set mid-workout, which is exactly the moment typing fails: hands
  busy, one-handed, out of breath. The strongest case for voice in the family.
- **Student notes** — a photographed whiteboard, a spoken thought after a lecture.

4 of 4 for both halves.

## The shape, and what it deliberately excludes

**Dictation hands back words, never audio.** Nothing in `Transcriber` returns a recording,
because none of the four apps wants one. Keeping audio out of the seam means audio never
has to be stored, synced, or explained to anybody — the strongest privacy position is the
one where the sensitive thing never exists.

**`TextRecognizer` takes `Data`, not an image type.** Nothing here touches UIKit, which
`AGENTS.md` allows only behind a justified wrapper, and a test can hand it three bytes.

**Microphone and speech recognition are separate permissions**, because iOS asks
separately and a person can say yes to one and no to the other. An app that treats them as
one thing will eventually show a broken screen to somebody who answered inconsistently.

**Permissions remember what was asked.** `docs/security.md` rule 4 says ask at the moment
it makes sense, never on launch. `InMemoryInputPermissions.asked` exists so an app's own
tests can prove it did not — a rule with a test is a rule; a rule in a document is a hope.

## Is this still the best way?

`AGENTS.md` asks this of every choice, and here the answer has a date on it.

**`SFSpeechRecognizer` is the right API today and probably not for long.** iOS 26 introduced
a newer speech transcription API. The foundation's minimum is iOS 18, so the older one is
what can actually be used — but this decision should be revisited the moment the minimum
rises, and the seam is drawn precisely so that when it happens, four apps do not care.

That is the seam earning its keep before it has an implementation behind it.

## What it costs

**`PPInput` is half a module**, and the roadmap says so. An app can build every screen and
still cannot hear anybody.

**The fakes might be wrong about how real dictation behaves.** `InMemoryTranscriber`
delivers improving guesses and one final transcript because that is the shape Apple's API
produces. If it turns out to differ — in how silence ends a stream, or how errors arrive
mid-stream — screens built against the fake will need adjusting. That is a real risk of
building the seam first, and it is smaller than the risk of building both blind.

## Revisit when

- There is a Mac and a device, at which point the implementations get written and this
  record gets an amendment saying how well the seams held.
- The deployment minimum rises past iOS 18 and the newer speech API becomes available.

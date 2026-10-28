# 0024 — Proving a request came from a genuine copy of the app

**Date:** 2026-10-28
**Status:** Proposed — nothing is built in the foundation yet, and nothing should
be until a second app needs it.

## What this proposes

Move the generic half of Spindle's App Attest client into the foundation: an
attested HTTP client that proves a request comes from a genuine copy of a
genuine app on a real device, with no account and no personal identifier.

## Why it is written down now, and not built now

`AGENTS.md` is explicit that the foundation becomes a junk drawer when things are
added before anything needs them, and moving working code out of a shipped app
carries risk for no user benefit. **Spindle is in TestFlight and working. Nothing
should be taken out of it today.**

What is worth capturing today is the *design*, while it is fresh and — more
importantly — while it is **proven**. It is running on real devices, against a
real server, and it survived the parts of App Attest that are easy to get wrong.
That is a rare thing to have, and it goes stale in memory long before it goes
stale in code.

## The foundation test — 4 of 4

The shared need is not "call a server". It is **spending money on somebody's
behalf without letting a stranger spend it too.**

- **Travel** — VEYA's backend is wide open today: anyone holding the anon key,
  which ships in the app, can call it.
- **Scripture study** — shipping this now, against a server holding an Anthropic
  key.
- **Fitness** — *"why did my squat plateau"* is a paid call, and the strongest
  case here rather than the weakest: a metered endpoint with no caller check is
  somebody else's free API, and the bill arrives monthly.
- **Student notes** — a lecture turned into flashcards, same shape, same bill.

## What is generic, and what is not

Of Spindle's 202-line `AppAttestStudyService`, roughly 150 lines are about
attestation and nothing else:

- generating a Secure Enclave key on first use and keeping its id
- fetching a challenge, attesting once, then signing each later request
- **noticing the key has been rejected and registering a new one**, which is what
  happens after a reinstall or a device restore and is the single most likely
  thing to be wrong in a hand-rolled version
- failing closed where App Attest is unavailable — the simulator, older devices —
  rather than quietly sending an unproven request
- turning Apple's and the server's errors into one sentence a person can read

The rest — which endpoints exist and what they return — is Spindle's and stays
there.

**The key id is deliberately not in the Keychain.** It is not a secret: the
server already knows it, and it is useless without the Secure Enclave key it
names. Ordinary settings are the right place, and writing that down stops the
next person "fixing" it.

## What it costs

**The foundation would own half a protocol.** Attestation is a conversation: the
client proves something and a server checks it. The foundation can own the client
half honestly, but it cannot own the server, so the record has to carry the wire
contract — challenge in, assertion out — or the next app invents a different one
and the two halves drift.

**It needs a capability on the App ID**, ticked in the developer portal, and an
entitlement in the build. A signed build without it fails in a way that does not
obviously mean "you forgot a checkbox".

**It is untestable where this foundation is written.** App Attest needs a real
device; a simulator refuses outright. The seam can be faked and the mapping can
be tested, and the attestation itself will be read and not run — as with
CloudKit, Sign in with Apple, and the rest.

## What this record deliberately does not decide

- **Which module.** `PPCore` is the obvious home and is already the place
  everything cross-cutting lands; a case exists for not putting a network client
  there at all.
- **Whether it generalises past Spindle's wire format** without a second app to
  design against. One real caller is a sample size of one.

## Revisit when

- A second app needs a backend it pays for — on current plans, VEYA.
- Apple changes App Attest, which would be better absorbed once than four times,
  and is most of the argument for this record existing at all.

# 0019 — Signing in is optional, and the name arrives once

**Date:** 2026-09-07
**Status:** Accepted

## What we decided

`PPAuth` ships the seam for signing in, with fakes. **Nothing in these apps requires an
account**, and the fake reproduces the one piece of Apple's behaviour that apps most often
get wrong.

## Signing in is not a wall

Everything on this foundation is stored on the phone and works with nobody signed in.
Signing in buys two things and only two: a person's own devices agreeing, and sharing
something with somebody else. It buys nothing else, and it is not what makes the app work.

So an app on this foundation must open, be useful, and let somebody write something down
before it has any idea who they are. A sign-in wall on the first screen is not a design
choice here, it is a misunderstanding of what the foundation is.

`NoAuthentication` is the default for exactly this reason: an app that signs nobody in is
a legitimate app, not a broken one.

## The thing Apple only does once

**Apple gives a person's name and email exactly once** — at the very first sign-in, on
that device, for that app. Not on the second sign-in. Not after a reinstall. Never again.

An app that does not save the name at that moment has lost it permanently, and will greet
somebody as "there" for the rest of the app's life. It is the most common way Sign in with
Apple is got wrong, and it is invisible in development because the first sign-in is the
one you keep testing.

`InMemoryAuthentication` reproduces it: the first `signIn()` returns the name and email,
every one after returns the identifier alone. **An app that forgets to save it fails a
test instead of disappointing somebody six months later.**

That is the same principle as `PPNotify`'s reminder limit — a fake that is *truer* than
convenient, in the direction that catches mistakes.

## Revocation, which no app can cause

Somebody can revoke an app from their Apple ID settings at any time. There is no way to
make that happen from inside an app, so it is the state an app is most likely to handle
badly and least likely to have ever seen.

`refresh()` exists so an app can ask on launch, and the fake has `revokeFromOutside()` so
the screen for it can be built at all.

## Cancelling is not an error

Somebody who dismisses the sign-in sheet knows what they did. `AuthFailure.isWorthShowing`
says so, and it is `false` for exactly one case. An app that shows an alert here is calling
a person's deliberate choice a problem.

## What we are not doing

- **No Apple implementation.** `AuthenticationServices` needs the entitlement, an Apple
  Developer account, and a device. The account does not exist yet, and the same argument
  as `0008` and `0015` applies: writing what nobody can verify is the expensive order.
- **No Keychain store.** The identifier belongs in the Keychain (`docs/security.md` rule
  2) and that implementation lands with the rest of it. Nothing in this work writes it
  anywhere, which is the safest possible position to be in meanwhile.
- **No second sign-in method.** `AGENTS.md` says Sign in with Apple unless an app genuinely
  needs another. None does.

## The foundation test

Travel shares a trip with a family; scripture study syncs a journal between a phone and an
iPad; student notes moves between devices; fitness carries a year of workouts to a new
phone. **4 of 4** — though fitness wants it for continuity rather than sharing, which is
the honest distinction.

## What it costs

`PPAuth` cannot sign anybody in. An app can build every screen — signed out, signing in,
cancelled, revoked — and none of them will do anything until there is an account and a
device.

## Revisit when

There is an Apple Developer account, at which point the implementation gets written and
this record gets a line about whether the seam held.

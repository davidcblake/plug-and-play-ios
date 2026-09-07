# 0020 — Deleting somebody means every module lets go, and the app says when

**Date:** 2026-09-07
**Status:** Accepted
**Follows:** 0019

## What we decided

Every module that holds a person's data can be told to let go of it, through one small
protocol in `PPCore`. **The app decides what to ask and in what order**, because only the
app knows every place it put something.

Deleting an account revokes the Sign in with Apple token. Signing out is not deletion.

## Why the app coordinates and the foundation cannot

`AGENTS.md`: feature modules never import each other. So `PPAuth` cannot see storage,
`PPData` cannot see the sign-in, and **nothing inside this foundation can see the whole of
what an app holds.** A coordinator living in either module would be a module reaching
across a line the rulebook draws.

The app is the only thing that can see all of it, so the app collects the pieces and
`PPCore` provides the shape they have in common.

**The gap this leaves, stated rather than hidden:** an app that adds a new place to store
things and forgets to add it to deletion will delete less than it claims, and nothing here
can catch that. Adding a store and adding it to deletion is one job, not two.

## Order matters, and it is the app's to get right

**Identity goes last.** Revoking somebody's sign-in first can take away the access needed
to delete the data it was protecting — most obviously anything in their private CloudKit
database. Delete what they wrote, then stop being able to recognise them.

## Partial failure is the dangerous case

If the local store is cleared and the cloud copy is not, somebody believes they are gone
and is not. That is worse than a plain failure, because they will stop asking.

So: **everything is asked even after one fails**, the report names what let go and what
did not, and `isComplete` is the only thing an app may show a "you have been deleted"
screen on. Stopping at the first failure leaves a person half-deleted with no way of
knowing which half, and the next attempt starting from an unknown state.

## Signing out is not deleting

Apple requires an app offering account creation to offer deletion, and for Sign in with
Apple that means revoking the token — not just forgetting the identifier locally. An app
that signs somebody out and calls it deletion gets rejected, and deserves to: it is a lie
told to somebody who asked to be forgotten.

One consequence worth knowing before it arrives as a support email: **somebody who deletes
and signs up again is a new person.** Apple treats a revoked account as never having
signed in, so the name arrives again — and an app storing it under the old identifier will
not recognise them. `InMemoryAuthentication` reproduces this.

## What we are not doing

- **No shared-record answer.** If somebody shared a trip and then deletes their account,
  what happens to the other person's copy is a real question with no obvious answer, and
  sharing does not exist yet. It gets decided when it does — and it must be, before
  sharing ships.
- **No grace period, no undo.** Deletion is immediate and final. A "you have thirty days
  to change your mind" flow means keeping data somebody asked to be rid of, which needs a
  better reason than convenience.
- **No export before delete.** Somebody may reasonably want their journal before it goes.
  Worth building; not required by Apple and not required to make deletion honest.
- **No Apple implementation**, per `0019` — revoking a token needs the Developer Program.

## The foundation test

Every app that offers sign-in must offer deletion — Apple's rule, not ours — so **4 of 4**
for any app that signs anybody in. An app that never signs anybody in does not need it,
which is another quiet argument for signing in staying optional.

## Revisit when

- Sharing exists, and somebody deletes an account with a shared record in it.
- An app wants to offer an export first.

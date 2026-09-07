# 0017 — Permission words live in `PPCore`

**Date:** 2026-09-07
**Status:** Accepted

## What we decided

`PermissionStatus` moves from `PPInput` to `PPCore`. Each module keeps its own list of
*what* it asks for; they all share the words for *where the answer stands*.

`PPOnboard` adds one thing on top: `PermissionApproach`, which turns a status into what an
app should actually do.

## Why it had to move

`AGENTS.md`: feature modules never import each other, they import `PPCore`.

`PPOnboard`'s whole job includes deciding when to ask for something, and it cannot ask that
question without the vocabulary for an answer. The vocabulary was in `PPInput`. Three
modules need it — the microphone and camera in `PPInput`, notifications in `PPNotify`, the
first-run flow in `PPOnboard` — so it belongs in the one module they all already import.

This is the rule working rather than the rule being annoying: the alternative was
`PPOnboard` importing `PPInput`, which is how four modules quietly become one.

`PPCore` gains a little scope. That is a real cost and worth naming: it was logging,
errors, configuration and flags, and it is now those plus one shared vocabulary. The line
is that `PPCore` holds words more than one module needs and behaviour none of them owns.
The *kinds* of permission stay where they are asked for.

## Status, and what to do about it, are different questions

The system knows four things: never asked, granted, denied, restricted. What an app should
*do* is a different list, and it is where apps get it wrong:

- **Never asked** → explain first, in the person's words, and only then show the system
  prompt. `docs/security.md` rule 4. iOS shows that prompt once, so an app that fires it
  cold spends its single chance on a stranger's guess.
- **Granted** → get on with it, and do not mention permissions at all.
- **Denied** → iOS will not ask again. Say what the feature would do and offer Settings.
  Once, where it is relevant, not as a nag.
- **Restricted** → stop offering. A managed device will never say yes, so a Settings link
  is a dead end.

Denied and restricted look the same to a careless app and are not the same. One has a way
back and the other does not.

Deciding this once, in one place, is the difference between four apps getting it right and
four apps each getting it subtly wrong.

## The foundation test

Every app on this foundation asks for something. Travel wants photos and probably location
later; scripture study wants the microphone for journalling out loud; fitness wants
notifications and health data; student notes wants the camera for a whiteboard. **4 of 4**
for the vocabulary, and 4 of 4 for knowing when to ask.

## What it costs

`PPInput` and its tests both changed shape for a module that did not exist yet, which is
the sort of churn a released package cannot afford. Nothing depends on this yet, so it is
free today and would not have been in a month.

## Revisit when

A permission arrives that does not fit four states — a partial grant, like a photo library
where somebody picks specific photos. That is a real case on iOS and this vocabulary does
not express it yet.

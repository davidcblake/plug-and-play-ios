# 0004 — iPhone only, shipped as a versioned Swift package

**Date:** 2026-09-05
**Status:** Accepted

## What we decided

**iPhone only.** No website version, no Android, for now.

**One Swift package with semantic version tags**, plus an app template cloned per app.
Apps depend on a tagged version, never on `main`.

## Why iPhone only

Building well for one platform beats building adequately for three. Every compromise that
makes code work across platforms costs something in how the app feels, and these are
consumer apps where feel matters.

It also unlocks the rest of the stack: CloudKit, StoreKit and Sign in with Apple are all
Apple-only, and choosing them is what removes the need for a server entirely.

If one product later earns a website or an Android version, that is a separate build
against the same ideas — a decision made per product, once it has users, rather than a
tax paid up front on every product including the ones that never find any.

## Why a versioned package, not a monorepo

**Release independence.** With everything in one project, shipping an update to the
scripture app means reasoning about whether unrelated travel app changes are safe, and
App Store review timelines start to tangle. With version numbers, each app upgrades when
its owner chooses.

**A change here can't break four apps at once.** An app pinned to version 1.4 is
unaffected by work on 1.5. This is the single most important property of the arrangement.

## Why not copy-and-modify

The obvious cheap alternative is to copy the last app and change it.

Rejected because fixes don't travel. Find a bug in the payment code in month four and
you fix it in five places and miss one. With a shared package, every app picks it up by
bumping a version number.

## What it costs

A change that affects all the apps at once needs a coordinated update in each app's
repository. Real friction, and worth it.

## The rule this creates

Nothing app-specific goes in the foundation. The test, in the pull request, every time:

> Would both a travel app and a scripture study app want this?

If no, it belongs in the app. This is what stops the foundation turning into a junk
drawer, which is how shared libraries usually die.

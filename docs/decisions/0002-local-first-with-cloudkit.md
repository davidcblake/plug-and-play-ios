# 0002 — Local-first storage, CloudKit for sync

**Date:** 2026-09-05
**Status:** Accepted

## What we decided

Every app stores its data on the device with SwiftData and works fully offline. CloudKit
syncs between a user's own devices and between people who share something. Sync sits
behind a `SyncProvider` protocol so it can be replaced.

## Why

**Offline is a requirement, not a feature.** A travel app is needed most when the signal
is worst. A scripture app is read on planes. Designing around a server means those apps
fail exactly when they matter.

**No server means no server problems.** No hosting bill, no database to run, no uptime to
worry about, no machine to patch, no 3am outage. For a portfolio of small apps built by
one person, this is the difference between shipping four apps and maintaining four
services.

**CloudKit is free and private.** It syncs across a user's devices at no cost, and the
private database is encrypted such that Apple cannot read it. For personal journals and
health data, that is a real selling point rather than a compromise.

**CloudKit sharing fits the first app exactly.** A family shares one trip itinerary —
everyone sees the same thing, offline, with no accounts to manage and no server anywhere.

## What we considered

**Supabase or a similar hosted backend.** More capable — real server-side logic,
cross-platform, queryable data. Costs money, needs maintaining, and requires building an
auth system. Correct answer if these apps needed websites. They don't.

**Firebase.** Same shape, plus bundled analytics and crash reporting. Heavier, less
SwiftUI-idiomatic, and a Google dependency.

**No sync at all.** Simplest. Rejected because "I lost my notes when I got a new phone"
is the kind of thing that kills an app's reputation permanently.

## The seam

Feature code never imports CloudKit. It talks to `SyncProvider`.

This costs roughly a day now. It buys the difference between "we'd rewrite the app" and
"we'd swap one piece" if an app later needs a website, an Android version, or
server-side logic. It also makes testing possible — a fake provider can simulate sync
failing, which cannot be done against CloudKit directly.

## What it costs us

CloudKit is Apple-only and runs no server-side logic. Both are deferred problems, not
solved ones. The first apps are iPhone-only by choice, so neither bites yet.

# 0009 — Migrations, and the one case that cannot be tested in memory

**Date:** 2026-09-07
**Status:** Accepted
**Follows:** 0008

## What we decided

`PPData` passes SwiftData's own migration machinery through and adds nothing to it. It
gains one thing of its own: `PPModelStore.Kind.stored(at:)`, a store at a named file, so
that migrations can actually be tested.

## Why almost nothing was built

SwiftData already has `VersionedSchema`, `SchemaMigrationPlan` and `MigrationStage`, and
they are good. The temptation was to wrap them in something friendlier. That would have
put a layer of ours between an app and the part of Apple's framework whose failure mode
is *a person losing what they wrote*. When this goes wrong, whoever is debugging it at
midnight should be reading Apple's documentation about Apple's types, not ours.

So the shape is: `container(for: TripSchemaV2.self, migrationPlan: TripMigrations.self)`.
One function, and the types in it are Apple's.

## Why `Kind.stored(at:)` had to exist

A migration only happens when a store that **already exists on disk** is opened by newer
code. That cannot be staged in memory, because a temporary store is empty every time. To
test a migration at all, a test must write with the old shape to a real file, close it,
and reopen the same file with the new one.

Which means: without this case, the migration path would have shipped untested, and the
next person would have found out whether it worked from a bug report. `AGENTS.md` asks
that every edge be fakeable in a test. This is the case where the edge is the disk itself.

It is deliberately never synced, for the same reason `.temporary` is not: a test that
reached iCloud would fail on an aeroplane and write to somebody's real account.

## The rule this puts on every app built here

**Once an app has shipped, its models are versioned.** After somebody has data on their
phone, changing a model is not a code change — it is a change to something a person owns.
It needs a version and a stage saying how to reach it from the last one.

Before the first release, none of this applies: there is nothing on anybody's phone, and
`container(for: [Trip.self])` is the right call.

## What is deliberately not here

**No recovery from a failed migration.** The obvious "helpful" move is to delete the
store and start clean when a migration fails. That is data loss, performed automatically,
on the day an app is least trustworthy. The container throws instead, and the app decides
— which at minimum means showing something rather than crashing on launch, because to the
person holding the phone those look identical.

**No custom-stage helper.** `.lightweight` covers adding a property with a default,
which is most changes. A custom stage that has to move data is app-specific, and Apple's
`willMigrate` / `didMigrate` are the right place for it.

## What it costs

Every app that ships has to learn what a `VersionedSchema` is. That is unavoidable — the
alternative is an app that cannot change its data shape without losing data.

## Revisit when

An app needs a custom stage in anger, and the shape of that turns out to be shareable.

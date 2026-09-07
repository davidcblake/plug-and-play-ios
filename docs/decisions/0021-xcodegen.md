# 0021 — The Xcode project is generated, not committed

**Date:** 2026-09-07
**Status:** Accepted

## What we decided

Apps built on this foundation describe their Xcode project in a readable `project.yml`,
and **XcodeGen** turns that into the `.xcodeproj`. The generated project is not committed.

This is a third-party dependency, which `AGENTS.md` says needs a written reason. Here it
is.

## What Apple's SDK cannot do

`.xcodeproj` is a directory containing `project.pbxproj`: a machine-written file of
hundreds of lines and generated identifiers. Apple provides no way to author or review it
as text, and no tool to produce one outside Xcode itself.

That matters for this project in three specific ways:

**Nobody can review it.** `AGENTS.md` says the person who owns this project is not an
engineer, and that a change he cannot follow in plain English is probably wrong. A diff in
`project.pbxproj` is unreadable to anybody. A diff in `project.yml` says "this app now
depends on `PPNotify`".

**Merge conflicts in it are unfixable.** Two branches each adding a file produce a
conflict in generated identifiers, and the usual resolution is to throw one side away and
redo the work by hand.

**It cannot be created here.** The agents doing most of the building run on Linux
containers with no Xcode. Without generation, every new app and every added file waits on
somebody being at a Mac — which is exactly the bottleneck this decision removes.

## Why XcodeGen rather than the alternatives

**Tuist** does more: it also manages dependencies, caching and a workspace graph. More
than is wanted. This foundation already has one way to declare dependencies — Swift
Package Manager — and a second one competing with it would be worse than the problem.

**A Swift Package alone** cannot be an iOS app. It has no bundle, no `Info.plist`, no
entitlements, nothing to sign, nothing to send to TestFlight.

**Committing the `.xcodeproj`** is the common choice and is what most projects do. It is
rejected for the three reasons above, and specifically because the middle one has already
bitten this kind of setup: several agents working in parallel on separate branches is
precisely the case that produces unresolvable project conflicts.

## What it costs, honestly

**A tool has to be installed** to open the project: `brew install xcodegen`, then
`xcodegen generate`. Anybody cloning this and expecting to double-click a project file
will not find one. That is a real papercut and it is why this record exists rather than
the decision being made quietly.

**XcodeGen is somebody else's project.** If it stops being maintained, the escape is to
generate the project once, commit it, and carry on — the cost of leaving is one command,
which is the test any dependency should pass before it is taken on.

**Xcode can still change the project**, and those changes are lost on the next generate.
The rule that follows: change `project.yml`, not the project. A setting toggled in Xcode's
interface and not written down will disappear, and it will disappear at the worst moment.

## What this unblocks

Phase 0's definition of done — "an empty app can depend on this package and it compiles" —
has never been met, and the roadmap has said so in a warning block since the beginning.
`Example/` is the first thing that has ever depended on this package.

It is also the first time any of `PPDesign` has been seen by a person. The whole design
system was built, reviewed and merged without anybody looking at it.

## Revisit when

- Apple ships a text-authorable project format. They have been asked for one for years.
- An app needs something XcodeGen cannot express, at which point the escape above applies.

# 0006 — Widen the foundation test from two apps to three of four

**Date:** 2026-09-05
**Status:** Accepted
**Amends:** 0004

## What we decided

The test that decides what belongs in the foundation was:

> Would both a travel app and a scripture study app want this?

It is now:

> Would at least three of the four planned apps want this — travel, scripture study,
> fitness, student notes? Name them, and say what each would use it for.

## Why

**Two apps was a weak test, because those two are the same shape.** Travel and scripture
study are both notes attached to a thing — a place, a passage. Something can satisfy both
and still be useless to the rest of the family. The foundation would pass its own test
right up until app three, and then not fit.

**Fitness is the odd one out, and that makes it the useful one to test against.** Its
data is numbers over time: weights, distances, durations. Student notes rejoins the
note-shaped group — lectures instead of passages. So of the four planned apps, three
share a shape and one does not, and a test that never mentions the different one is not
really testing generality at all.

**Naming the apps is the part with teeth.** "Would a couple of apps want this?" is
answerable yes from an armchair. "Name three and say what each does with it" is not — it
is where you discover that two of them wanted subtly different things and the shared
version serves neither well.

## Why three and not four

Requiring all four would push genuine foundation work out.

Sharing a record between people is the clearest example. A family shares a trip
itinerary; a family might share a study; a study group shares notes. The fitness app
almost certainly never wants it. Sharing plainly belongs in `PPData` — a rule that
excluded it would be wrong, and a rule people have to quietly ignore stops being a rule.

## Why there is an escape hatch at all

The goal is a foundation that is strong across several *kinds* of app. The goal is not
alignment for its own sake. Those come apart in both directions, and the rule has to
survive both:

- **Forcing a fit.** Inventing a use the fitness app would never really have, so the
  count reaches three and the addition goes in. The rule then launders a bad decision
  instead of catching it.
- **Forcing an exclusion.** Pushing something out that obviously belongs here because it
  only reaches two. Sharing is the standing example.

So falling short of three is a **no by default**, overridable by a decision record that
names the apps, argues why it belongs here anyway, and says what leaving it out would
cost. Expensive enough to stay rare, possible enough that nobody has to quietly break the
rule to do the right thing.

This deliberately reuses the mechanism already in `AGENTS.md` for third-party
dependencies and `@unchecked Sendable`: the thing is not banned, it costs a written
argument that someone else can attack. A rule with no exception gets broken silently. A
rule with a cheap exception is not a rule.

## The failure mode this guards against

The obvious way to widen the test is to ask "would lots of apps want this?" That is
**worse than the rule it replaces**, because it is vaguer, and a vague test is a weaker
gate. The entire job of this rule is to make it hard to add things. Any amendment has to
make the question harder to answer yes to, not easier.

## What it costs

More work per pull request. Every addition now needs three named apps and three concrete
uses written down, rather than a yes-or-no.

That is the point. If an addition cannot survive being described three ways, it was not
foundation, and the cost of finding out in a pull request is far lower than the cost of
finding out on app four.

## Revisit when

The set of planned apps changes. This rule names four specific apps, so if one is dropped
or another added, the rule has to be re-derived rather than patched — including which of
them is now the odd shape out.

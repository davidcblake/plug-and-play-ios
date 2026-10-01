# 0014 — What the model may say, and what happens when it is wrong

**Date:** 2026-09-07
**Status:** Proposed
**Depends on:** 0010

## What we decided

Each app owns its own voice and writes its own instructions. The foundation provides the
place to put them, the handling for when a model refuses, and one rule that binds every
app: **generated content is always marked as generated, and always points at something a
person can check.**

## The thing this is really about

A generative model will eventually produce something wrong. Not might — will. The question
a decision record can usefully answer is not "how do we prevent that" but **"what happens
when it does."**

The answer is that it should be *checkable*, *clearly not authoritative*, and *easy to
throw away*.

## The rule that binds every app

**Generated content says so, and cites what it drew on.**

For a study of a passage, that means the passage. For a claim about what a talk said, the
talk. For a training suggestion, the logged sessions behind it. Not because a citation
makes a model correct — it does not — but because it makes a person able to check, and it
turns "the app said so" into "the app said so, and here is where to look."

An app that produces confident unsourced paragraphs is asking for trust it has not earned,
and it will spend that trust the first time it is wrong.

## What each app has to decide for itself

**Scripture study** is the one with the most at stake, and it carries a specific risk
the others do not: **an app must never appear to speak for the Church.** A generated study
that reads like doctrine, in an app made for members, is a serious thing to get wrong. So
for that app: the voice is plainly the app's own, drawn from the standard works and the
teachings of living prophets; it points at the passages so a person reads the actual text;
and it never presents itself as official teaching. Spindle's own README already commits to
devotional content that does not surface controversy or criticism, and that commitment
belongs in the app's instructions rather than in someone's memory.

**Fitness** has a line at medical advice. Encouraging somebody through a plateau is one
thing; telling them what a pain in their knee is, is another, and an app that crosses that
line is one bad week away from a real problem.

**Student notes** has one that is easy to miss: **an app that writes the essay is a
different product from one that helps somebody understand the material.** Which of those
it is should be decided deliberately, by a person, not arrived at by adding features.

**Travel** is the mildest, and still has one: confidently wrong opening hours or a
confidently wrong direction is how somebody's afternoon gets wasted in a city they saved
two years to visit.

## Refusals are normal, and are not errors

A model may decline. It arrives as a successful response that contains a refusal rather
than an answer, and an app that does not check for it will show a person something
strange, or nothing at all, with no explanation.

Every app handles it the same way: say plainly that this one could not be answered, leave
everything the person already had untouched, and offer the way forward that does not
involve a model. That is `PPError`'s existing split doing its job — one message for the
person, the detail in the log.

## What we are not doing

- **No review queue.** Nothing generated here is published to other people; it is made for
  the person who asked. If an app ever shares generated content between people, that is a
  new decision and a much harder one.
- **No foundation-level content filter.** A shared filter across four unrelated apps would
  be wrong for all of them. Each app's instructions are its own; the foundation does not
  get an opinion about scripture, medicine or essays.
- **No claim that instructions are a guarantee.** They shape what a model does. They do not
  bind it. Which is exactly why the citation rule above matters more than the wording of
  any instruction.

## What it costs

**Citations are work**, and sometimes they are not available — a model's general knowledge
has no source to point at. Content that cannot cite anything should be shorter and more
plainly hedged, which means the app is less impressive on purpose.

**Marking content as generated makes the app feel less magical.** That is the correct
trade. The alternative is a person mistaking a machine's paragraph for a settled truth,
and in the scripture app that is not a UX problem.

## Revisit when

- An app wants to share generated content between people, which reopens all of this.
- Something goes wrong in a way this record did not anticipate. Add it to the list rather
  than rewriting the principle.

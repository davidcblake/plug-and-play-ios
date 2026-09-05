# 0005 — Use gstack's tooling, but not its review commands

**Date:** 2026-09-05
**Status:** Accepted

## What we decided

Use gstack — an open-source pack of Claude Code skills — for its build-and-ship tooling.
Do **not** use its review commands, and do **not** install its "required" enforcement
mode in this repository.

## Why use it

gstack packages a lot of well-worn workflow into single commands: `/ship`, `/qa`,
`/investigate`, `/retro`, `/document-release`, `/autoplan`. That is work nobody here
wants to write from scratch, and none of it conflicts with anything in `AGENTS.md`.

## Why not its review commands

gstack's headline commands include `/review`, `/plan-eng-review`, `/plan-ceo-review` and
`/design-review`. All of them are Claude reviewing work Claude wrote.

`AGENTS.md` has exactly one rule marked as unbendable: **whoever writes something never
reviews it.** The entire reason this project pays for four AIs from four companies is
that they have different blind spots. A Claude review of Claude's own code collapses that
back into one opinion while still *feeling* like review, which is worse than no review at
all — it produces confidence without independence.

That seat belongs to Grok, and to Codex when its credits are back. So the tooling comes
in and the review commands stay out.

This is not hypothetical. gstack's own installer wrote instructions into `CLAUDE.md`
telling Claude that `/review` is available. Left alone, adopting this tool would have
quietly softened the one rule the project says must never bend — which is exactly how it
got softened twice before, per the September handoff notes.

## Why not "required" mode

gstack offers a team mode that commits an enforcement hook into the repository. The hook
blocks all skill usage unless gstack is found in one of about a dozen paths — every one
of them under `$HOME`, on the machine running the AI tool. Nothing about the install
travels in the repository; only the requirement does.

That breaks badly here specifically. This project is worked on from ephemeral cloud
containers, where `$HOME` is wiped between sessions. Every new session would start
blocked, and gstack's `./setup` cannot complete in that environment anyway — the network
policy blocks the browser download it ends with.

So the requirement would be enforced in exactly the environments that cannot satisfy it.
We took the skills and left the enforcement.

## What it costs

gstack is installed per-machine, so it will be absent in a fresh cloud session until
someone clones it. That is a deliberate trade: an occasional missing convenience beats a
hook that halts work on a machine that cannot fix itself.

We are also now depending on a third-party skill pack that can change under us. It is
pinned to nothing — a fresh clone takes whatever `main` holds that day.

## Revisit when

**Pinning:** at the first gstack update that changes behaviour we relied on, or by
2026-12-31, whichever comes first. Pin to a tag at that point. Leaving this open-ended
is how an unpinned dependency quietly becomes permanent.

**The review commands:** when Codex and Gemini are connected and the review seats are
genuinely covered. The argument against `/review` is unchanged then, but the cost of not
having it is even lower.

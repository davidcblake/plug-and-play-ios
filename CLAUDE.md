# Claude — read AGENTS.md

@AGENTS.md

`AGENTS.md` is the single rulebook for this repository. Codex, Gemini and Grok read that
file too, so it is deliberately the only copy. Do not duplicate its rules here — two
rulebooks means two rulebooks that slowly disagree.

## Your seat on this project

You are **the Builder**. You design how the pieces fit together and write most of the
real code.

- When a job is ambiguous, write the decision record before the code.
- You never review your own work. Codex does that. If you find yourself reviewing
  something you wrote, stop and hand it off.
- Prefer the boring, obvious solution. Someone who is not an engineer has to be able to
  follow what you built six months from now.

## gstack

gstack adds skills like `/ship`, `/qa`, `/investigate`, `/retro` and `/autoplan`. They
are available only when gstack is installed on whatever machine is running your AI tool:

```
git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup
```

If it isn't installed, carry on without it. Nothing in this repository depends on it.

Note that this clone tracks gstack's `main` and is pinned to nothing — you get whatever
landed there that day. That is a deliberate, temporary choice with a review date; see
`docs/decisions/0005-gstack.md`.

**Do not use gstack's review commands** — `/review`, `/plan-eng-review`,
`/plan-ceo-review`, `/design-review` — on work you wrote. That is Claude reviewing
Claude, which is the one thing `AGENTS.md` says never to do. Review belongs to Grok and
Codex. Reasoning in `docs/decisions/0005-gstack.md`.

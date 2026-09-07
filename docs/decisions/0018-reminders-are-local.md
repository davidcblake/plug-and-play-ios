# 0018 — Reminders happen on the phone

**Date:** 2026-09-07
**Status:** Accepted

## What we decided

`PPNotify` ships the seam for **local** reminders — scheduled on the device, fired by the
device, needing no server, no account and no network. Push notifications are not in this
piece of work.

## Why local first, and possibly local only

A local reminder is the same shape as everything else in this foundation: the phone is
told once and does the rest by itself. It keeps arriving on a plane, in a canyon, with the
phone offline for a week. Nothing to run, nothing to pay for, nothing to be down at 3am.

Push is the opposite. It needs an Apple Developer account, certificates, and a server with
something worth saying. Two of those do not exist and the third is not obviously wanted:
of the four planned apps, **none has yet named a thing that has to be pushed.** A daily
study reminder, a workout nudge, an assignment due date and a departing flight are all
things the phone already knows.

So push waits, and may turn out never to be needed. That is worth saying out loud rather
than treating push as inevitable and half-building it.

## The foundation test

- **Travel** — your flight is tomorrow; today is day three of the trip.
- **Scripture study** — the daily study reminder. Spindle's entire loop depends on
  somebody coming back tomorrow, and this is the thing that asks them to.
- **Fitness** — workout time; nothing logged in three days.
- **Student notes** — an assignment is due Thursday.

4 of 4, and all four are things the phone can work out for itself.

## The two mistakes this design makes impossible

**Duplicate reminders.** A reminder carries an id, and scheduling the same id twice
replaces rather than adds. The classic bug is rescheduling a daily reminder on every
launch and giving somebody forty identical notifications; here that cannot happen by
accident.

**Silently losing reminders.** **iOS keeps at most 64 pending local notifications per app
and discards the rest without a word.** An app that schedules one reminder a day for a
year is not scheduling 365 things — it is scheduling 64 and losing 301 silently.

`InMemoryReminders` is deliberately **stricter than the real system**: it throws on the
sixty-fifth rather than discarding it. A test double that is more permissive than reality
lets bugs through; one that is stricter turns a silent production failure into a loud test
failure, which is the direction that helps. The way out is a repeating schedule, which
costs one.

## What we are not doing

- **No push.** See above.
- **No permission handling here yet.** Notification permission uses the same vocabulary
  `PPOnboard` needs, which is moving to `PPCore` in a separate piece of work. Doing both at
  once would have made two reviewable things into one unreviewable one.
- **No weekly or monthly schedules.** Weekday numbering is a trap — Apple counts Sunday as
  one — and nothing has asked for it yet.
- **No notification content beyond a title and a line.** No images, no actions, no sounds.
  Those are real and they should arrive when an app wants one.

## What it costs

`PPNotify` is half a module and the roadmap says so. Nothing here has fired a real
notification, because that needs a device and a person waiting until tomorrow morning.
What is tested is the part that can be: what an app scheduled, and whether it made either
of the two mistakes above.

## Revisit when

An app names something that genuinely has to be pushed from elsewhere — a message from
another person is the likeliest — at which point push stops being speculative and gets
designed against a real use.

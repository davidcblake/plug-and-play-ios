# 0007 — What goes in `PPDesign`, and how it is built

**Date:** 2026-09-06
**Status:** Accepted

## What we decided

`PPDesign` ships eleven colors, seven text styles, one spacing scale, and five
components: a button style, a card, an empty state, a failure view, and a number readout.
Colors are written as plain hex numbers and injected through the SwiftUI environment;
type and spacing are constants. Readability is enforced by a test, not by eye.

---

## The foundation test

`AGENTS.md`: *would at least three of the four planned apps want this — travel, scripture
study, fitness, student notes? Name them, and say what each would use it for.* Tested
hardest against fitness, because fitness is numbers over time while the other three are
notes attached to a thing.

### Colors — `PPColor`, `PPTheme` (4 of 4)

- **Travel** — a trip card on a background, an accent on "Add a trip", red on "Delete
  trip", and a dark appearance that works on a phone in a hotel room at night.
- **Scripture study** — a reading surface that is comfortable for a long sitting, and an
  accent for a highlight.
- **Fitness** — a green for a goal met and a red for a missed one, and dark mode in a
  badly lit gym. Color is the fastest way to say "you hit it" without words.
- **Student notes** — an accent on a due date, red on an overdue one.

### Typography — `PPTextStyle` (4 of 4, unevenly)

- **Travel** — screen and card titles, body for notes, small text for dates.
- **Scripture study** — body text is the app. It is the reason `body` and `caption` are
  set in Apple's plain typeface rather than the rounded one used elsewhere: rounded is
  friendly on a heading and tiring over a chapter.
- **Fitness** — `number`, with monospaced digits so a timer or a rep count does not
  shuffle sideways as its digits change. This style exists because of the fitness app.
  Honestly: fitness barely uses `body` at all.
- **Student notes** — the same long-form reading need as scripture, plus headings.

### Spacing and corners — `PPSpacing`, `PPRadius` (4 of 4)

Every app puts things on a screen with gaps between them. The value is not the numbers,
it is that four apps built at four different times line up, because nobody typed `13`.

`minimumTapTarget` is here for a specific reason, and the reason is fitness: mid-workout,
one-handed, sweaty, is the hardest tapping condition any of these apps will meet. A
44-point floor set once beats four apps each discovering it.

### `PPButtonStyle` (4 of 4)

- **Travel** — "Add a trip", "Delete trip".
- **Scripture study** — "Save highlight", "Start a study".
- **Fitness** — "Start workout", "Finish set". The one with the hardest tapping
  conditions, per above.
- **Student notes** — "New note", "Mark done".

### `PPCard` (4 of 4)

- **Travel** — a day of an itinerary.
- **Scripture study** — a saved passage.
- **Fitness** — a finished workout, or a block of numbers for the week.
- **Student notes** — a lecture.

Tested against fitness deliberately: a card holding three numbers is not the same shape
as a card holding a paragraph, which is why `PPCard` sets the surface, the inset and the
corner and lays out **nothing** inside itself. A card component that decided its own
internal arrangement would have been a notes-only component wearing a general name.

### `PPEmptyState` (4 of 4)

Every one of these apps opens for the first time with nothing in it. "No trips yet", "no
highlights yet", "nothing logged this week", "no notes yet". The first screen a person
sees is empty, and it is the screen that decides whether they come back.

### `PPErrorView` (4 of 4)

All four save to disk and sync, so all four can fail at it. What this really shares is
`PPCore`'s rule that a failure has one message for a person and another for the log: this
is the component that makes the rule hold, because a screen that gets its failure text
from here cannot show "SQLITE_FULL: disk image is malformed" to anybody.

### `PPMetric` (4 of 4, and the one that proves the rest)

- **Fitness** — steps, weight, a personal best. Its primary customer.
- **Travel** — days until the trip, spend against budget.
- **Student notes** — assignments due this week, hours studied.
- **Scripture study** — chapters read, days in a row.

Honest about the count: fitness would use this constantly, student weekly, travel and
scripture occasionally. It reaches four, but not evenly.

It is included because a design system built only from the pieces the note-shaped apps
want is exactly the failure `AGENTS.md` warns about — three similar apps sharing a
feature and calling it a foundation. `PPMetric` and `PPTextStyle.number` are the parts
that are there for app three.

### What we deliberately left out

- **A loading spinner.** Local-first says nothing waits on a server for an answer it
  already has. A spinner component in the shared kit is an invitation to build screens
  that wait. If sync progress needs one later, it belongs next to sync, with a real case
  behind it.
- **A note or entry row.** Travel, scripture and student notes would all want one. That
  is three of four — but all three are the same shape, and it is a shared feature of
  three similar apps, not foundation. This is precisely the count the "test it hardest
  against fitness" rule exists to catch.
- **Charts.** Fitness, and at a stretch student. One and a half of four. Apple's Swift
  Charts already exists; apps that need it can use it directly.
- **Tags, badges, search fields, date pickers.** Nobody has needed one yet. A design
  system earns its keep by being small.
- **An icon set.** SF Symbols is Apple's, free, and already on the phone.

---

## How it is built, and why

### Colors are numbers in a Swift file, not an asset catalogue

Apple's asset catalogue is the normal home for colors and is the right answer inside an
app. For a shared foundation it is the wrong one:

- **A test can read a number.** The palette's readability is checked by machine — every
  text color against every surface it is drawn on, in both appearances, against the WCAG
  standard. A color set in an asset catalogue cannot be read by a unit test without a
  running app, so accessibility would be checked by eye, once, by whoever was looking.
- **A diff can be reviewed.** `0x0E6E62` in a pull request is a change somebody can see.
  A changed `Contents.json` inside a color set is not.
- **No resource bundle.** No `.process` resources in `Package.swift`, and no chance of a
  module that works in the package and not in an app that consumes it.

The cost, stated plainly: no color picker in Xcode, and no previewing a color without
building. That is a real loss for whoever is choosing colors. It is worth it for a
palette that is tested rather than eyeballed.

### A color is a pair, and there is no way to write one that is not

`PPColor` requires a light value and a dark value. The most common way a finished-looking
app looks unfinished is one screen that forgot dark mode; here that is a compile error,
and a test also fails if the two values are identical.

### `PPColor` is a `ShapeStyle`

So `foregroundStyle(theme.textPrimary)` works and the call site never reads the color
scheme. The alternative — every view holding `@Environment(\.colorScheme)` and picking —
is the kind of ceremony that gets forgotten in one place and then looks wrong in dark
mode.

### Colors are injected, type and spacing are not

Apps genuinely differ in color: a travel app and a scripture app should not share an
accent. They do not differ in how far apart things sit or how large a heading is. A value
nobody varies gains nothing from being injectable and costs a parameter on everything
that reads it. If an app ever does need its own type scale, this decision gets revisited
rather than worked around.

### A custom button style rather than Apple's `.borderedProminent`

`AGENTS.md` says Apple's frameworks first, so this needs a reason. Apple's bordered
styles take a tint and decide height, corner radius and label weight themselves, and what
they decide changes with control size and with the iOS version. Four apps shipping on
four schedules would drift apart on exactly the three things that make apps look
related — and `.borderedProminent` does not promise a 44-point tap target at its default
size.

This is the one place we chose our own over Apple's. If a future iOS makes the built-in
styles configurable on those three points, the right move is to delete this and use
Apple's.

### `PPEmptyState` wraps Apple's `ContentUnavailableView` rather than replacing it

Apple's version already handles the layout, the type scaling and the centring, and it is
what people are used to seeing. The wrapper adds one thing: the family's button on the
action. If it ever grows past that, the honest question is whether it should exist at all.

### Components take text, not numbers or dates

`PPMetric` takes `"12,340"`, not `12340`. Turning a number into text depends on the
person's locale, their units and what the number means, and none of that is knowable
inside a design component. Apps format with Apple's `FormatStyle` and hand the text over.

The same reasoning applies to translation: these components show the strings they are
given, and exactly one piece of text is English in the source — the "Try again" button on
`PPErrorView`, which is a parameter with a default rather than a fixed string.
Localization is a real gap and is listed as such in the roadmap rather than half-built
here.

## What this costs

Someone choosing a color cannot use Xcode's color picker, and nobody has yet seen any
of this on a screen — there is no app to run it in until the example host app exists.
Everything asserted here is asserted by a test or by reading, not by looking.

## Revisit when

- The first app is built on it and something is awkward in practice. That is the real
  test, and it has not happened yet.
- An app needs its own type scale or spacing, which would mean those belong in the theme
  after all.
- Apple's built-in button styles become configurable enough to replace `PPButtonStyle`.

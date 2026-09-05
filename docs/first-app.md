# First app — the travel app

The foundation's first real customer, and the thing that proves it works.

**Being specific here is the point.** A specification that describes any app describes no
app, and gives the AIs nothing to build against.

## What it is

A travel companion for a family trip abroad. Itinerary, places, notes, and the practical
information you need while actually walking around a foreign city.

## The constraint that shapes everything

**It has to work with no signal.**

This is not a nice-to-have. The app is used abroad, on roaming data that is expensive,
throttled or absent, in a city where you don't speak the language. The moment you most
need to know which train, which street, what time the tickets are for, is exactly the
moment your phone says "no internet."

Every screen works in airplane mode. If a feature can't, it doesn't ship.

This is also why the travel app is the right first customer: it stress-tests the
foundation's most important promise on day one, rather than letting it stay theoretical
until app three.

## What it does

**Trip overview** — dates, where you're staying, who's coming, what's happening today.
The screen you open twenty times a day.

**Day-by-day itinerary** — what's planned, in order, easy to rearrange when plans change.
Plans always change.

**Places** — restaurants, sites, churches, shops. Each with a short note on why it's
worth going and anything useful (opening hours, whether to book, what to order).

**Map** — where things are, relative to where you're staying. Offline map data, because
a map that needs a connection is not a travel map.

**Notes and essentials** — confirmation numbers, useful phrases, emergency contacts,
where the passports are. Voice notes and photos, because typing on a phone while walking
is miserable.

**Shared with the family** — everyone sees the same trip. One person adds a restaurant,
everyone has it. Via CloudKit sharing: no server, no accounts to manage, works offline
and syncs when signal returns.

## What it deliberately does not do

- No booking or payments. Book on the web like a normal person.
- No social features. This is for one family, not an audience.
- No live prices, weather or transit times — they all require a connection, which
  defeats the point.
- No AI features in version one. Get the fundamentals right first.

## What it takes from the foundation

Storage and sync, sharing, the design system, onboarding, voice-to-text and photo
capture, notifications. All of it.

## What it builds itself

The trip data model, the itinerary screens, the map, and the specific content.

**That split is the test.** If the app-specific part is small and the foundation part is
large, the foundation is doing its job. If the app ends up reaching around the foundation
or reimplementing pieces of it, say so plainly in the roadmap — that's the foundation
being wrong, and it's much cheaper to learn now than on app four.

## Success looks like

You're standing on a street in a foreign city with no data connection, you open the app,
and within two seconds it tells you where you're going and how to get there.

And someone else in the family, on their own phone, sees the same thing.

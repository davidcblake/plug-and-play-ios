# 0003 — Apple's in-app purchases for subscriptions

**Date:** 2026-09-05
**Status:** Accepted

## What we decided

Subscriptions run through StoreKit 2 — Apple's own in-app purchase system. Not Stripe,
not a web checkout.

## Why

**It's what users expect and trust.** Payment happens with Face ID and a card Apple
already has. No forms, no card entry, no "is this site safe?" moment. Conversion is
materially better.

**One implementation serves every app.** `PPPay` is built once. App four gets
subscriptions by adding a product identifier.

**No compliance burden.** No card data, no PCI scope, no tax registration in dozens of
jurisdictions, no chargeback handling. Apple does all of it.

**Apple manages the awkward parts** — free trials, renewals, upgrades and downgrades,
family sharing, refunds, and cancellations — with no code from us.

## What it costs

**Apple's commission: 15%** under the Small Business Program, for developers earning
under $1M a year. The standard rate is 30%.

**Apply for the Small Business Program.** It is not automatic, and halving the commission
is worth the twenty minutes it takes.

## What we considered

**Web checkout with Stripe.** Keeps more revenue. In the US, apps may now link out to
their own checkout for digital subscriptions, which was not true a few years ago.

Rejected for now on three grounds: it doubles the plumbing, the rules differ by country
(most places outside the US require a special entitlement and extra disclosure), and
Apple has proposed taking a cut of external purchases too — so a plan built on keeping
100% may not survive.

The previous version of this project used Stripe specifically because it never went
through the App Store. That reason no longer applies.

**Both together.** Defensible later, at real revenue, where 15% of a large number is
worth the complexity. Not now.

## Revisit when

Annual revenue makes the 15% material enough to justify running two payment paths and
the country-by-country rules that come with them.

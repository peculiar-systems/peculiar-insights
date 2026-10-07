---
title: Privacy and consent
section: Comply
order: 9
---

# Privacy and consent

This page is for the developer wiring an SDK. The model itself is described on [the consent page](/privacy).

## What the SDK enforces

- Nothing is persisted and no connection is opened before a purpose is granted.
- Items recorded before a decision wait in a bounded in-memory buffer and are sent on grant or discarded on denial.
- Every batch carries the consent snapshot, and the server refuses what was not granted.
- Withdrawing a purpose drops that purpose's queued items and sends one withdrawal record; once no purpose remains granted, the device id and user id are dropped as well.
- In the browser, Global Privacy Control counts as a denial unless the product overrides it.

## What you must do

1. Start the SDK with a `ConsentPolicy`. `ask` wires the product's own prompt: when the user decides, call `insights.consent.grant(purpose, policyVersion)` or `insights.consent.withdraw(purpose)`. `assumed` takes a basis per purpose and records an automatic grant with that basis as the policy version, for products whose legal basis needs no prompt.
2. Offer `analytics` and `diagnostics` as separate choices unless the product's policy combines them.
3. Change the policy version string whenever the policy changes, so the ledger shows which text a user accepted.
4. Never put personal data in event names, property keys, custom keys or log lines. User ids must be the product's opaque ids.
5. Put `insights.erase()` behind the account deletion flow.
6. Do not grant in code to make dashboards light up. That defeats the system and is a compliance failure.

## Verifying

With consent declined, the dashboards stay empty and the SDK sends no requests. With consent granted, events appear within seconds. Subscribe to `insights.diagnostics` during development: a not-consented item means a call happened before consent.

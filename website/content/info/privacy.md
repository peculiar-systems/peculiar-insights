---
title: The consent model
section: Privacy
order: 2
---

# The consent model

Insights treats consent as a property of the system, not a checkbox in the app. This page describes what the SDKs and the server do, in the order a user experiences it.

## Two purposes

`analytics` covers events, identities, sessions and profiles. `diagnostics` covers crash reports and log lines. A user grants or withdraws each independently. A product may default either one where its jurisdiction allows, but the SDK never grants on its own.

## Before a decision

Until a purpose is decided, the SDK writes nothing to disk and opens no connection. Items for that purpose accumulate in a bounded in-memory buffer under a device id that exists only in memory. A grant persists the device id and flushes the buffer. A denial or a process exit discards both. A fatal crash before a diagnostics decision is therefore lost, because writing it to disk would be storage without consent.

## Consent is a record

Grants and withdrawals are stored on the server with the purpose, the policy version the user accepted and the time. That is the proof of consent. A denial that follows no grant is never sent, because sending it would itself be processing.

## On every batch

Each batch carries a snapshot of the purpose states and policy versions. The server refuses items whose purpose is not granted, so a defective client cannot store unconsented data. Refusals are visible to the SDK as per-item outcomes.

## Withdrawal

Withdrawing a purpose stops capture for it, drops that purpose's queued items, and sends one withdrawal record. Once no purpose remains granted, the device id and the user id are dropped too. Withdrawal and erasure are distinct, as the law treats them.

## Erasure

`erase` from inside the app sends a tombstone for the current device id and, when the user is identified, the linked person. The server erases both and records the request. The scope is what the device can prove it is, so an ingest key cannot erase arbitrary users. Operators can also erase a person by user id with the `admin.delete_person` SQL function.

## Global Privacy Control

The browser SDK treats the Global Privacy Control signal as a denial of both purposes unless the product overrides it explicitly. The Flutter SDK does the same on the web.

## Minimisation

No IP addresses are stored. Context is typed and narrow: SDK and app version, platform, OS, device model, locale, timezone, screen size. A client-side scrubber, opt in, redacts emails, phone numbers and card numbers from crash messages, log lines and string properties. A per-project property denylist on the server is the second line.

## Inventory and manifest

Every collected field in the contract carries a data category and a purpose. A task generates the data inventory document and the Apple privacy manifest from those annotations, so a field cannot be collected without being declared, and a check fails when either file drifts from the contract.

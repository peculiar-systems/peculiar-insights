---
title: Architecture
section: Architecture
order: 3
---

# Architecture

Four parts, one contract. This page describes them in the order data flows.

## The contract

`proto/peculiar/insights/v1` defines one `Ingest` service with three unary calls: `Publish` for batches of events, identities, profile updates and crash reports; `RecordConsent`; and `RequestErasure`. Property values are a typed oneof of string, integer, double, boolean, timestamp, list and map. Every collected field carries a data category and a consent purpose as custom options. `buf lint` and `buf breaking` run in the repository's gate, because a cached client outlives a deploy and an old client will meet a new server.

## The SDKs

Each SDK batches items with client-generated UUIDs, a sent-at timestamp and the consent snapshot, and delivers at least once with exponential backoff on transport failures only. The server deduplicates on the item id, so delivery is exactly once in effect. Metadata carries the ingest key and the SDK protocol version; the server refuses a version it no longer understands.

## The server

One Haskell binary serves native gRPC, gRPC-Web and Connect on one port, with optional TLS chosen by ALPN. For each item it validates limits, checks consent, corrects the client timestamp using the batch's sent-at, deduplicates, resolves the person, and writes. Batches are not atomic: valid items are accepted and invalid ones rejected with a per-item outcome, so one bad event never blocks a queue.

## Identity

The model is a simplified id merge. A device id is minted on first launch. `identify` links the device to a person; the server resolves the person at ingest and backfills that device's earlier anonymous events onto them in the same transaction. `reset` mints a new device id.

## Sessions

Sessions are owned by the SDK: a new one after thirty minutes of inactivity, and on mobile after returning from the background past the same threshold. The server records session start and end, and marks a session crashed when a fatal report arrives.

## Crashes

A report carries the exception type, message, raw frames, fatal flag, thread, build, typed context, custom keys and recent log lines. Frames carry instruction addresses and binary images where the platform has them, and Flutter reports are symbolicated from the symbols each build uploads, the raw frames kept beside them. Grouping fingerprints on the exception type plus the normalised top in-app frames. Issues are open, resolved or ignored; a resolved issue that reappears on a newer build is reopened and marked regressed. Breadcrumbs are not duplicated; they are the session's preceding events, fetched by query.

## Storage

PostgreSQL, with the schema owned by the server through explicit migrations. Events and crashes are partitioned by month; a maintenance loop creates partitions ahead and enforces per-project retention. Raw tables are private. A `reporting` schema of views and SQL functions, including `funnel` and `retention`, is what Grafana reads through a read-only role; the cohorts, funnels, retention analyses and metrics declared in the module are installed there as views at every start. An `admin` schema holds `resolve_issue`, `ignore_issue`, `reopen_issue` and `delete_person`.

## Grafana

Vanilla Grafana with the built-in PostgreSQL datasource, provisioned by the NixOS module. On a host where the module runs both, the reader role is `grafana` and connects over the local socket with peer authentication, so no database password exists anywhere.

---
title: Overview
section: Start
order: 1
---

# Documentation

Insights is a self-hosted analytics and crash tracking system. This documentation covers running it, reading it in Grafana, operating it, and integrating its SDKs.

## What is where

| You want to                                            | Read                                                                                              |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| Go from nothing to a first event                       | [Getting started](/docs/getting-started)                                                          |
| Run the server, PostgreSQL and Grafana on a NixOS host | [Deploying with NixOS](/docs/deploying)                                                           |
| Understand the dashboards and alerts                   | [Grafana](/docs/grafana)                                                                          |
| Triage issues, erase people, regenerate the inventory  | [Operations](/docs/operations)                                                                    |
| Wire consent correctly in a product                    | [Privacy and consent](/docs/privacy)                                                              |
| Integrate an SDK with an agent                         | [For agents](/docs/agents)                                                                        |
| Look up an SDK                                         | [Flutter](/docs/sdks/flutter), [TypeScript](/docs/sdks/typescript), [Haskell](/docs/sdks/haskell) |

## The shape of an integration

1. Deploy the module and declare a project next to the product it measures; the service generates the ingest key.
2. Add an SDK to the product and start it with the URL, the key and a consent policy.
3. Wire the product's consent prompt to `insights.consent`.
4. Record through trackers: `track`, `identify`, `people`, `recordError`, `attempt`, `span`.
5. Open Grafana.

## Repository

The source is at [github.com/peculiar-systems/peculiar-insights](https://github.com/peculiar-systems/peculiar-insights). `DECISIONS.md` records every product decision; `README.md` describes the layout and the development tasks. Everything is a Nix task and `nix flake check` is the only gate.

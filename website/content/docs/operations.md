---
title: Operations
section: Observe
order: 8
---

# Operations

Configuration is declarative: projects, environments, keys, retention and analytics live in the NixOS module, and Grafana edits none of them. Triaging issues and erasing people are actions in the Grafana dashboards, open to a Grafana Admin only.

## Issue triage

On the Issue dashboard the Issue panel offers Resolve, Ignore and Reopen for the issue shown; on the Crashes dashboard every row of the Issues table offers the same for its issue. Grafana asks to confirm, then the issue's state changes.

Resolving records the build the issue was last seen on, so a crash on a newer build reopens it as regressed and the regression alert fires. Ignoring stops it counting as open. Reopening puts it back to open and clears the resolved build.

## Erasure by an operator

On the People dashboard, the panel of the selected user offers Erase. It asks for confirmation and runs only once confirmed. It deletes the person's events, crashes, sessions and consent records in that project and environment, unlinks their devices, deletes the person, and records an erasure. In-app erasure through the SDK covers the common case; this action is for requests that arrive by other means.

## Who may act

The actions post JSON through Grafana's data source proxy to the server's `peculiar.insights.v1.Manage` service, which wraps the `admin` schema's functions (`admin.triage`, `admin.delete_person`). Grafana forwards the ID token it signs for the signed-in user; the server verifies it against Grafana's signing keys and refuses a request whose identity is missing, invalid, or not an Admin of the organisation, whatever the dashboard shows and wherever the request came from. An Editor or a Viewer sees the buttons and is refused.

## Rate limits

Every environment's key has a budget of items, by default 6000 a minute sustained and 12000 at once, set with `rateLimit` and lifted with `null`. A call that would exceed it is refused with `RESOURCE_EXHAUSTED` and the header `x-peculiar-retry-after-ms`, and every SDK keeps what it was sending and sends it again after that delay. Nothing is dropped for being throttled. `peerLimit` adds a budget per network peer, whatever key it presents, for a server that phones and browsers reach directly.

## Monitoring the server

With `monitoring.enable` the server answers `GET /metrics` on a port of its own, 9464 by default, in the Prometheus text format:

| Series                                                | Labels                              | Meaning                                   |
| ----------------------------------------------------- | ----------------------------------- | ----------------------------------------- |
| `insights_requests_total`                             | `method`, `code`                    | Calls answered, by gRPC status.           |
| `insights_request_seconds_total`                      | `method`                            | Seconds spent answering calls.            |
| `insights_items_total`                                | `project`, `environment`, `outcome` | Items received, by what became of them.   |
| `insights_rate_limited_total`                         | `scope`, `project`, `environment`   | Calls refused for exceeding a limit.      |
| `insights_storage_failures_total`                     | `operation`                         | Storage operations that failed.           |
| `insights_maintenance_runs_total`                     | `result`                            | Maintenance passes.                       |
| `insights_maintenance_last_success_timestamp_seconds` |                                     | When maintenance last succeeded.          |
| `insights_projects`                                   |                                     | Environments the server accepts data for. |
| `insights_start_timestamp_seconds`                    |                                     | When the server started.                  |

The port is separate from the one SDKs reach, so it is never published with it.

## Keys

A generated key lives at `/var/lib/peculiar-insights/keys/<slug>-<environment>`, readable only by the service. To rotate it, delete the file and restart the service; a new key is generated and every product using the old one stops being accepted until it is updated. A provided `keyFile` is rotated by replacing the file it points at and restarting.

## Declared analytics

Cohorts, funnels, retention and metrics declared in the module are installed as views in the reporting schema at every start, named `cohort_`, `funnel_`, `retention_` and `metric_` followed by `<slug>_<environment>_<name>`. Changing a declaration and rebuilding the host replaces the view, and a view whose declaration was removed is dropped.

`peculiar-insights-server --check <config.json>` reads a configuration the way the server would and says whether it is valid, without touching the database or the keys. The module's own check runs it on what the module renders.

## Maintenance

An hourly loop inside the server creates the monthly partitions for events and crashes ahead of time, deletes data past each project's retention, drops partitions that are wholly past the retention when every project has one, prunes the deduplication table, and deletes the symbols of builds no longer kept, as [Uploading symbols](/docs/sdks/symbols) describes. It is journalled as `maintained`, `maintenance-failed` or `maintenance-crashed` in the service's log.

## Journal

The server writes JSON lines to stdout: `listening`, `monitoring`, `started`, `request-failed`, `publish-failed`, `consent-failed`, `erasure-failed` and the maintenance entries. systemd's journal collects them.

## The data inventory

`PRIVACY.md` and the Flutter plugin's `PrivacyInfo.xcprivacy` are generated from the contract's field annotations. After changing the proto, run `nix run .#inventory`; `nix flake check` fails when either committed file drifts from the generated one.

## Development tasks

```
nix run .#tasks-help     every task
nix run .#codegen        materialise generated protobuf code for editors
nix run .#inventory      regenerate PRIVACY.md and the privacy manifest
nix run .#fmt            format Haskell and Nix
nix run .#lint           hlint with the shared ruleset
nix flake check          build, test, format, lint, proto lint
```

The server test suite starts an ephemeral PostgreSQL inside the check, so no database needs to exist on the machine running it.

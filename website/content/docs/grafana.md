---
title: Grafana
section: Observe
order: 7
---

# Grafana

Dashboards and alert rules are files that vanilla Grafana loads through provisioning. No community plugins are needed. Every panel and variable query was executed against the migrations in an ephemeral PostgreSQL before it landed in the repository.

## Variables

Every dashboard starts with `project` and `environment`, listed from the devices the server has seen. Time ranges apply to the event, session or crash time, never to the receive time.

## Dashboards

| Dashboard          | What it shows                                                                                                                                                                         | Extra variables                                           |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Overview           | Events, active users, sessions, crash-free rate, open issues and new people for the range, with trends and the top events and issues                                                  | none                                                      |
| Event segmentation | Trends of the chosen events, a breakdown by the value of one property key, and splits by event, platform and app version                                                              | `event`, `platform`, `app_version`, `property`, `cohort`  |
| Funnel             | People who reached each step in order within the conversion window, with overall and step-to-step conversion                                                                          | `steps` (event names in order, comma separated), `window` |
| Retention          | A cohort matrix of the share of people who did the return event N periods after first doing the birth event, plus cohort sizes and the average curve                                  | `birth`, `return`, `period`, `periods`                    |
| People             | A searchable profile list and a drilldown for one user id: properties, devices, sessions, events and crashes                                                                          | `search`, `user`                                          |
| Crashes            | Crash-free sessions and users over time, fatal and non-fatal crashes, the issue list, and splits by app version and platform                                                          | none                                                      |
| Issue              | One issue: its history, crashes by build and platform, the latest crash with frames, custom keys, log lines and raw stack trace, and the events of the crashed session as breadcrumbs | `issue`                                                   |
| Consent            | Grants and withdrawals over time by purpose, the state currently in force per device, policy versions, and erasures                                                                   | none                                                      |

Issue ids and user ids in tables link to the issue and people dashboards. The funnel and retention panels of the shared dashboards call the SQL functions `reporting.funnel` and `reporting.retention` installed by the server's migrations; the declared ones call `reporting.funnel_steps` and `reporting.retention_matching`, which also match on property values. A declared metric with a measure plots the aggregate, with the event count on the right axis.

## Actions

| Dashboard | Panel                         | Actions                                          |
| --------- | ----------------------------- | ------------------------------------------------ |
| Issue     | Issue                         | Resolve, Ignore and Reopen the issue shown       |
| Crashes   | Issues, on each row           | Resolve, Ignore and Reopen the issue of that row |
| People    | The selected user, at the top | Erase the person, after confirming               |

Only a Grafana Admin can act; the server checks the identity Grafana signs for the signed-in user and refuses everyone else. What each action does is described in [Operations](/docs/operations).

## Project folders

An environment that declares funnels, retention, metrics or cohorts gets a dashboard of its own, generated from the declaration and provisioned into the folder `Insights · <slug> / <environment>` with the title `<slug> / <environment>`. It holds one bar chart with conversion stats per funnel, one cohort matrix with the average curve per retention analysis, one time series of daily events and people per metric, and a table of cohort sizes when cohorts exist. Every panel follows Grafana's time range. The eight shared dashboards stay in the "Peculiar Insights" folder and keep working for every environment.

The declarations are described in [Deploying with NixOS](/docs/deploying). The same declarations produce reporting views over a fixed lookback, `reporting.funnel_<slug>_<environment>_<name>` and its siblings, for Explore and for tools other than Grafana.

## Alerts

Rules are provisioned into the folder "Peculiar Insights" and evaluate every five minutes. Every rule groups by project and environment.

| Rule                                 | Fires when                                                                                                     |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| New crash issue                      | An issue was first seen in the last 15 minutes                                                                 |
| Crash issue regressed                | A resolved issue reappeared on a newer build in the last 15 minutes                                            |
| Crash-free sessions below 95 percent | Over the last hour, with at least 20 sessions, fewer than 95 percent were crash-free, sustained for 10 minutes |
| Ingest silence                       | An environment that had events in the last 24 hours received none in the last 30 minutes                       |

## Writing your own panels

The reporting schema is the public surface: `reporting.event`, `reporting.person`, `reporting.device`, `reporting.session`, `reporting.issue`, `reporting.crash`, `reporting.consent`, `reporting.erasure`, `reporting.crash_free_daily`, the cohort views, the declared funnel, retention and metric views, and the `funnel` and `retention` functions. Properties are `jsonb`; extract with `properties->>'key'`. Raw tables are not visible to the reader role. Explore is for a one-off question; anything worth keeping belongs in a declaration.

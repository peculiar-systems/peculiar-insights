# Grafana

Everything a person sees lives here: dashboards and alert rules that vanilla
Grafana loads through file provisioning. No community plugins are needed. The
NixOS module provisions them together with a PostgreSQL datasource whose uid is
`peculiar-insights` and whose role may only read the `reporting` schema, and a
management datasource whose uid is `peculiar-insights-manage`, which points at
the server and carries the actions below.

## Variables

Every dashboard starts with `project` and `environment`, listed from the devices
the server has seen. The other variables are per dashboard and are described
below. Text boxes take free text; query variables list what exists in the data.
Time ranges apply to the event, session or crash time, never to the receive time.

## Dashboards

| Dashboard | What it shows | Extra variables |
|---|---|---|
| Overview | Events, active users, sessions, crash-free rate, open issues and new people for the range, with trends and the top events and issues | none |
| Event segmentation | Trends of the chosen events, a breakdown by the value of one property key, and splits by event, platform and app version | `event` (multi), `platform` (multi), `app_version` (multi), `property` (a key of the chosen events), `cohort` (everyone, or a cohort declared in the server configuration) |
| Funnel | People who reached each step in order within the conversion window, with overall and step-to-step conversion | `steps` (event names in order, comma separated), `window` |
| Retention | A cohort matrix of the share of people who did the return event N periods after first doing the birth event, plus cohort sizes and the average curve | `birth`, `return`, `period` (day, week or month), `periods` |
| People | A searchable profile list and a drilldown for one user id: properties, devices, sessions, events and crashes | `search`, `user` |
| Crashes | Crash-free sessions and users over time, fatal and non-fatal crashes, the issue list, and splits by app version and platform | none |
| Issue | One issue: its history, crashes by build and platform, the latest crash with frames, custom keys, log lines and raw stack trace, and the events of the crashed session as breadcrumbs | `issue` |
| Consent | Grants and withdrawals over time by purpose, the state currently in force per device, policy versions, and erasures | none |

Issue ids and user ids in tables link to the issue and people dashboards.

The funnel and retention panels call the SQL functions `reporting.funnel` and
`reporting.retention` installed by the server's migrations, so the logic has one
home and one test.

## Actions

A Grafana Admin triages issues and erases people from the dashboards:

| Dashboard | Panel | Actions |
|---|---|---|
| Issue | Issue | Resolve, Ignore and Reopen the issue shown |
| Crashes | Issues, on each row | Resolve, Ignore and Reopen the issue of that row |
| People | The selected user | Erase the person, after confirming |

Resolving records the build the issue was last seen on, so a crash on a newer
build regresses it; ignoring stops it counting as open; reopening puts it back
to open and clears the resolved build. Erasing deletes the person and
everything recorded for them in that project and environment, unlinks their
devices, and records the erasure.

Each action is a panel action that posts JSON through Grafana's data source
proxy to the `peculiar.insights.v1.Manage` service of the server. Grafana
forwards the ID token it signs for the signed-in user, and the server checks it
against Grafana's signing keys and refuses anyone whose role in the
organisation is not Admin, whatever the dashboard shows. The module allows
those posts with Grafana's `security.actions_allow_post_url`.

## Alerts

Rules are provisioned into the folder "Peculiar Insights" and evaluate every five
minutes. No contact point is provisioned: notification routing is the host's
decision, so route on the `source=peculiar-insights` label.

| Rule | Fires when |
|---|---|
| New crash issue | An issue was first seen in the last 15 minutes |
| Crash issue regressed | A resolved issue reappeared on a newer build in the last 15 minutes |
| Crash-free sessions below 95 percent | Over the last hour, with at least 20 sessions, fewer than 95 percent were crash-free, sustained for 10 minutes |
| Ingest silence | An environment that had events in the last 24 hours received none in the last 30 minutes |

Every rule groups by project and environment, so one alert fires per affected
environment.

## Project folders

The NixOS module generates one more dashboard per environment that declares
funnels, retention, metrics or cohorts, from `nixos/dashboards.nix`, and
provisions it into the folder "Insights · <slug> / <environment>". It contains
a bar chart with conversion stats per funnel, a cohort matrix with the average
curve per retention analysis, a daily time series per metric, and a table of
cohort sizes. The eight dashboards in this directory stay in the "Peculiar
Insights" folder.

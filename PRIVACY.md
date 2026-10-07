# Data inventory

Generated from the field annotations in `proto/peculiar/insights/v1`. Every collected field is listed with its category, the consent purpose that gates it, and the matching App Store privacy label and Google Play data safety type. Do not edit by hand; run the inventory task.

## None

App Store: not a declared data type. Google Play: not collected as personal data.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.Context` | `app_build` |  |
| `peculiar.insights.v1.Context` | `app_version` |  |
| `peculiar.insights.v1.Context` | `sdk_name` |  |
| `peculiar.insights.v1.Context` | `sdk_version` |  |
| `peculiar.insights.v1.CrashReport` | `id` |  |
| `peculiar.insights.v1.Event` | `id` |  |
| `peculiar.insights.v1.Identify` | `id` |  |
| `peculiar.insights.v1.Identify` | `time` |  |
| `peculiar.insights.v1.ProfileUpdate` | `id` |  |
| `peculiar.insights.v1.ProfileUpdate` | `time` |  |
| `peculiar.insights.v1.RecordConsentRequest` | `id` |  |
| `peculiar.insights.v1.RecordConsentRequest` | `purpose` |  |
| `peculiar.insights.v1.RecordConsentRequest` | `time` |  |
| `peculiar.insights.v1.RequestErasureRequest` | `id` |  |
| `peculiar.insights.v1.RequestErasureRequest` | `time` |  |

## Device ID

App Store: Device ID. Google Play: Device or other IDs.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.Identify` | `device_id` | analytics |
| `peculiar.insights.v1.ProfileUpdate` | `device_id` | analytics |
| `peculiar.insights.v1.RecordConsentRequest` | `device_id` |  |
| `peculiar.insights.v1.RequestErasureRequest` | `device_id` |  |
| `peculiar.insights.v1.Subject` | `device_id` |  |
| `peculiar.insights.v1.Subject` | `session_id` |  |

## User ID

App Store: User ID. Google Play: User IDs.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.Identify` | `user_id` | analytics |
| `peculiar.insights.v1.ProfileUpdate` | `user_id` | analytics |
| `peculiar.insights.v1.RecordConsentRequest` | `user_id` |  |
| `peculiar.insights.v1.RequestErasureRequest` | `user_id` |  |
| `peculiar.insights.v1.Subject` | `user_id` |  |

## Device info

App Store: not a declared data type. Google Play: not a listed data type.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.Context` | `device_model` |  |
| `peculiar.insights.v1.Context` | `locale` |  |
| `peculiar.insights.v1.Context` | `os_name` |  |
| `peculiar.insights.v1.Context` | `os_version` |  |
| `peculiar.insights.v1.Context` | `platform` |  |
| `peculiar.insights.v1.Context` | `screen_height` |  |
| `peculiar.insights.v1.Context` | `screen_width` |  |
| `peculiar.insights.v1.Context` | `timezone` |  |

## Product interaction

App Store: Product interaction. Google Play: App interactions.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.Event` | `name` | analytics |
| `peculiar.insights.v1.Event` | `time` | analytics |

## Crash data

App Store: Crash data. Google Play: Crash logs.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.CrashReport` | `exception_type` | diagnostics |
| `peculiar.insights.v1.CrashReport` | `fatal` | diagnostics |
| `peculiar.insights.v1.CrashReport` | `frames` | diagnostics |
| `peculiar.insights.v1.CrashReport` | `message` | diagnostics |
| `peculiar.insights.v1.CrashReport` | `raw_stack_trace` | diagnostics |
| `peculiar.insights.v1.CrashReport` | `thread` | diagnostics |
| `peculiar.insights.v1.CrashReport` | `time` | diagnostics |
| `peculiar.insights.v1.Frame` | `image` | diagnostics |
| `peculiar.insights.v1.Frame` | `instruction_address` | diagnostics |
| `peculiar.insights.v1.Image` | `identifier` | diagnostics |
| `peculiar.insights.v1.Image` | `load_address` | diagnostics |
| `peculiar.insights.v1.Image` | `name` | diagnostics |

## Other diagnostic data

App Store: Other diagnostic data. Google Play: Diagnostics.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.CrashReport` | `logs` | diagnostics |

## User content

App Store: User content. Google Play: Other user-generated content.

| Message | Field | Purpose |
|---|---|---|
| `peculiar.insights.v1.CrashReport` | `custom_keys` | diagnostics |
| `peculiar.insights.v1.Event` | `properties` | analytics |
| `peculiar.insights.v1.ProfileUpdate` | `operations` | analytics |


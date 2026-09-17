# Salesforce Adapter

Queries and updates Salesforce records via the REST API. Receives inbound data specifying what to query or modify, executes the operation, and pushes results downstream.

| | |
|---|---|
| **Slug** | `salesforce_adapter` |
| **Node type id** | `LKBZ_SALESFORCE_ADAPTER` |
| **Node type** | transform |
| **Version** | 1.0.0 |
| **Interval driven** | no |
| **Libraries** | salesforce 1.0.0 |

## Configuration

| Field | Type | Default | Notes |
|---|---|---|---|
| Domain | string | _(empty)_ | Salesforce instance domain, e.g. myorg.my.salesforce.com. Do not include the https:// prefix. |
| Client ID | string | _(empty)_ | OAuth 2.0 client_id from the connected app configuration in Salesforce Setup. |
| Client Secret | password | _(empty — set on the node)_ | OAuth 2.0 client_secret from the connected app configuration. |
| Key | password | _(empty — set on the node)_ | Pre-existing bearer token. If set, the adapter uses this token directly instead of authenticating via client_credentials. Leave empty for normal OAuth flow. |
| API Version | string | `59.0` | Salesforce REST API version number, e.g. 59.0. Used to build the /services/data/v<version>/ path. |
| Live Mode | bool | `true` | When off, API requests are simulated and no data leaves the runtime. Authentication is always performed live so credential problems surface immediately. |
| Verify TLS | bool | `true` | Whether to verify the Salesforce server's TLS certificate. Leave on outside of local testing. |

## Samples

De-identified messages you can run the node against:

- `samples/query_and_update.json`
- `samples/query_only.json`

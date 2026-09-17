# `salesforce` 1.0.0

Salesforce REST API client. Handles OAuth 2.0 client_credentials authentication and provides query, modify, modifyBatch, delete and custom request helpers. Copy the salesforce/ folder into a node and add it to package.path.

| | |
|---|---|
| **Library** | `salesforce` |
| **Version** | 1.0.0 |
| **Immutable** | yes — a fix ships as a new version directory |

## Modules

- `salesforce/salesforce.lua`
- `salesforce/salesforce_auth.lua`
- `salesforce/salesforce_http.lua`
- `salesforce/salesforce_token.lua`

## Using it

A node that pins this library gets the `salesforce/` folder copied in beside its script. Add it to `package.path` and require the entry module:

```lua
local salesforce = require("salesforce.salesforce")
```

# `dynamics_crm` 1.0.0

Microsoft Dynamics 365 CRM client. Handles OAuth 2.0 authentication against Azure AD and provides FetchXML query and generic request helpers. Copy the dynamics_crm/ folder into a node and add it to package.path.

| | |
|---|---|
| **Library** | `dynamics_crm` |
| **Version** | 1.0.0 |
| **Immutable** | yes — a fix ships as a new version directory |

## Modules

- `dynamics_crm/dynamics_crm.lua`
- `dynamics_crm/dynamics_crm_auth.lua`
- `dynamics_crm/dynamics_crm_http.lua`
- `dynamics_crm/dynamics_crm_token.lua`

## Using it

A node that pins this library gets the `dynamics_crm/` folder copied in beside its script. Add it to `package.path` and require the entry module:

```lua
local dynamics_crm = require("dynamics_crm.dynamics_crm")
```

# Linkiir Business Adapters

Enterprise business systems: CRM, ERP, ITSM, HR, identity and directory services, and scheduling and workforce operations.

**Catalog id:** `lkbz` — every node template in this catalog carries a `LKBZ_` node type id.
**Published adapters:** 2 &nbsp;•&nbsp; **Published libraries:** 2

---

## Subscribe

In Grid, go to **Settings → Catalogs → Subscribe** and paste:

```
https://github.com/Linkiir/linkiir-business-adapters
```

This is a public repository, so Grid clones it anonymously and no SSH key is needed. Leave **Ref** at `main` to track the latest published content.

Install it under the name **`linkiir-business-adapters`**. The install name is recorded on every node built from this catalog, so keeping it consistent makes a node's origin readable in support.

Subscribing needs the **Manage catalogs** permission (Administration tier).

## Published adapters

| Adapter | Slug | Node type | Node type id | Version | Libraries |
|---|---|---|---|---|---|
| Dynamics CRM Adapter | `dynamics_crm_adapter` | source | `LKBZ_DYNAMICS_CRM_ADAPTER` | 1.0.0 | dynamics_crm 1.0.0 |
| Salesforce Adapter | `salesforce_adapter` | transform | `LKBZ_SALESFORCE_ADAPTER` | 1.0.0 | salesforce 1.0.0 |

## Published libraries

| Library | Version | Purpose |
|---|---|---|
| `dynamics_crm` | 1.0.0 | Microsoft Dynamics 365 CRM client. Handles OAuth 2.0 authentication against Azure AD and provides FetchXML query and generic request helpers. Copy the dynamics_crm/ folder into a node and add it to package.path. |
| `salesforce` | 1.0.0 | Salesforce REST API client. Handles OAuth 2.0 client_credentials authentication and provides query, modify, modifyBatch, delete and custom request helpers. Copy the salesforce/ folder into a node and add it to package.path. |

## Roadmap

| Adapter | Node type | Connects to | Status |
|---|---|---|---|
| Salesforce Health Cloud | transform | Health Cloud object model | Planned |
| ServiceNow Adapter | source, destination | ITSM incidents | Planned |
| Jira Adapter | source, destination | Jira and JSM issues | Planned |
| SAP S/4HANA / Oracle ERP / NetSuite / Workday | source, destination | ERP and HR | Planned |
| LDAP / Active Directory / Entra ID / Okta | source | identity and directory | Planned |
| SCIM 2.0 Provisioning | destination | user provisioning | Planned |
| QGenda / TeleTracking / symplr / Phreesia / Luma | source, destination | scheduling and operations | Planned |

Status meanings: **Next** is in active development, **Planned** is scoped but not started. See [the Integration Network](https://linkiir.com/network/) for the full adapter list and where each one stands.

## Configuration and credentials

Every adapter ships with its credential fields **empty**, and that is deliberate. Password fields are encrypted with each grid's own key, so a value shipped from here could not decrypt on your machine — it would fail with an error blaming your key. Fill them in on the node after you build it.

Two fields appear on most adapters and are worth knowing:

- **Live Mode** — when off, requests are prepared and logged but never sent. Use it to prove configuration before touching a real system.
- **Verify TLS** — leave on. Turn it off only against a local service with a self-signed certificate.

## Support and status

Adapters here are **Beta** unless the roadmap table says otherwise: they work and run somewhere, but the template is still being finished, so expect a Linkiir engineer alongside you on a first deployment. **GA** means the template is hardened and running across multiple customers.

Every adapter has a named owner at Linkiir who maintains it. For a problem with a specific adapter, quote its node type id.

## Versioning

- **Adapters** are versioned by the `version` field in `node_config.json`. A change that does not move the version forward is refused by the validator.
- **Library versions are immutable.** A published `libraries/<name>/<version>/` directory is never edited; a fix ships as a new version directory. Several versions sit side by side and each node pins the one it uses, so updating this catalog cannot disturb a node pinned to an older library.

Before applying an update, Grid shows you the incoming commit and diff. Read [CHANGELOG.md](CHANGELOG.md) for what changed and why.

## Repository layout

```
catalog.json                              the manifest Grid validates
nodes/<slug>/node_config.json             an adapter's definition
nodes/<slug>/*.lua                        its scripts
nodes/<slug>/samples/                     de-identified test messages
libraries/<name>/<version>/library.json   a published library version
libraries/<name>/<version>/<name>/*.lua   its modules
```

The layout is identical to Grid's own on-disk layout, so a pull needs no transform.

---

Published by Linkiir Inc. Part of the [Linkiir catalog set](https://github.com/Linkiir?q=adapters) — see [the Catalogs documentation](https://help.linkiir.com/docs/catalogs/) for how catalogs reach a grid.

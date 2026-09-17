# Dynamics CRM Adapter

Polls a Microsoft Dynamics 365 CRM instance with a FetchXML query on each interval and pushes each matching record downstream as JSON.

| | |
|---|---|
| **Slug** | `dynamics_crm_adapter` |
| **Node type id** | `LKBZ_DYNAMICS_CRM_ADAPTER` |
| **Node type** | source |
| **Version** | 1.0.0 |
| **Interval driven** | yes |
| **Libraries** | dynamics_crm 1.0.0 |

## Configuration

| Field | Type | Default | Notes |
|---|---|---|---|
| Interval | number | `60000` | How often, in milliseconds, the runtime invokes the polling script. |
| URL | string | _(empty)_ | Base URL of the Dynamics 365 instance, e.g. https://org.crm.dynamics.com/. The Web API path (api/data/v9.2/) is appended to it, so a trailing slash is expected (one is added if omitted). |
| Username | string | _(empty)_ | Azure AD username for the Resource Owner Password Credentials grant. |
| Password | password | _(empty — set on the node)_ | Password for the Azure AD user account. |
| FetchXML Query | string | `<fetch distinct="false" mapping="logical" output-format="xml-platform" version="1.0">
   <entity name="ccx_master_queue">
      <attribute name="ccx_name"/>
      <attribute name="createdon"/>
      <attribute name="ccx_recordtype"/>
      <attribute name="ccx_processeddate"/>
      <attribute name="ccx_processed"/>
      <attribute name="ccx_interfacename"/>
      <attribute name="createdby"/>
      <attribute name="ccx_master_queueid"/>
      <order descending="true" attribute="createdon"/>
      <filter type="and">
         <condition attribute="statecode" value="0" operator="eq"/>
         <condition attribute="createdon" value="{{curr_date}}" operator="on"/>
      </filter>
   </entity>
</fetch>` | The FetchXML query to execute on each poll. Use {{curr_date}} as a placeholder for today's date (YYYY-MM-DD). The entity name in the query determines which entity set is queried. |
| Live Mode | bool | `true` | When off, requests are simulated and no data leaves the runtime. Authentication is always performed live so credential problems surface immediately. |
| Verify TLS | bool | `true` | Whether to verify the Dynamics server's TLS certificate. Leave on outside of local testing against a proxy. |

-- ---------------------------------------------------------------------------
-- Dynamics CRM Adapter - Source Custom
--
-- Runs on the node's Interval. Each poll executes the configured FetchXML
-- query against the Dynamics 365 Web API and pushes each matching record
-- downstream as a JSON document.
--
-- What to change where:
--   FetchXML Query and the connection fields  ->  node config
--   the shape of what gets pushed             ->  this script
--   how Dynamics is called                    ->  dynamics_crm library
-- ---------------------------------------------------------------------------

-- The library modules live in the dynamics_crm/ subfolder, so add it to the
-- module search path before requiring them.
package.path = linkiir.sys.nodeDir() .. '/dynamics_crm/?.lua;' .. package.path

local DynamicsCrm = require 'dynamics_crm'

-- Substitute {{curr_date}} with today's date in YYYY-MM-DD format.
local function substituteDate(Query, Crm)
   if not Query then return '' end
   return Query:gsub('{{curr_date}}', Crm:formatDate())
end

function main()
   local Crm, Config = DynamicsCrm.fromNodeConfig()

   local Query = Config['FetchXML Query']
   if not Query or Query == '' then
      linkiir.log.error('Dynamics CRM Adapter: FetchXML Query is not configured.')
      return
   end

   -- Replace date placeholders before sending the query.
   Query = substituteDate(Query, Crm)

   local Records, Err = Crm:fetchXml{ query = Query }

   if not Records then
      linkiir.log.error(string.format(
         'Dynamics CRM Adapter: FetchXML query failed [%s] %s',
         tostring(Err.code), tostring(Err.message)))
      return
   end

   if Records.simulated then
      linkiir.log.info('Dynamics CRM Adapter: Live Mode is off, no request was sent.')
      return
   end

   if #Records == 0 then
      linkiir.log.info('Dynamics CRM Adapter: no records matched the query.')
      return
   end

   for _, Record in ipairs(Records) do
      linkiir.flow.push{ data = linkiir.json.serialize(Record) }
   end

   linkiir.log.info(string.format(
      'Dynamics CRM Adapter: pushed %d record(s).', #Records))
end

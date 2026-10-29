-- ---------------------------------------------------------------------------
-- dynamics_crm - Microsoft Dynamics 365 CRM client
--
-- Require this module. The others (auth, http, token) are internals.
--
--    local DynamicsCrm = require 'dynamics_crm'
--
--    function main()
--       local Crm, Config = DynamicsCrm.fromNodeConfig()
--
--       local Records, Err = Crm:fetchXml{
--          query = Config['FetchXML Query'],
--       }
--       if not Records then
--          linkiir.log.error(Err.message)
--          return
--       end
--
--       for _, Record in ipairs(Records) do
--          linkiir.flow.push{ data = linkiir.json.serialize(Record) }
--       end
--    end
--
-- Every method returns a result, or nil plus an error table:
--
--    local Records, Err = Crm:fetchXml{ query = xml }
--    if not Records then
--       -- Err.code and Err.message are always set. Depending on the failure,
--       -- Err may also carry http_code or body.
--    end
--
-- Authentication is automatic: the first call that needs a token fetches one
-- via a password grant and later calls reuse it until it nears expiry.
-- ---------------------------------------------------------------------------

local Http = require 'dynamics_crm_http'
local Auth = require 'dynamics_crm_auth'

local DEFAULT_TIMEOUT  = 30
local DEFAULT_API_PATH = 'api/data/v9.2/'

-- ---------------------------------------------------------------------------
-- Client methods
-- ---------------------------------------------------------------------------

local Client = {}
Client.__index = Client

-- Execute a FetchXML query against the Web API.
--
-- FetchXML is passed as the `fetchXml` query parameter on a GET to the entity
-- set. The entity name is extracted from the query itself.
--
--   T.query   - the FetchXML string (required)
--   T.entity  - override the entity set name; if omitted, extracted from the
--               <entity name="..."> element in the query
--   T.headers - extra headers
--   T.live    - overrides the client's live flag for this call
--
-- Returns the array of records, or nil plus an error table.
function Client:fetchXml(T)
   if not T or not T.query or T.query == '' then
      return nil, {
         code    = 'QUERY_ERROR',
         message = 'FetchXML query is empty',
      }
   end

   -- Determine the entity set name from the query or the override.
   local EntityName = T.entity
   if not EntityName or EntityName == '' then
      EntityName = T.query:match('<entity%s+name="([^"]+)"')
   end
   if not EntityName or EntityName == '' then
      return nil, {
         code    = 'QUERY_ERROR',
         message = 'cannot determine entity name from FetchXML; set T.entity explicitly',
      }
   end

   -- Dynamics Web API uses the plural entity set name. Add an 's' if it does
   -- not already end with one. This handles the common case; override with
   -- T.entity for irregular plurals (e.g. "addresses").
   local EntitySet = EntityName
   if EntitySet:sub(-1) ~= 's' then
      EntitySet = EntitySet .. 's'
   end

   local Result, Err = Http.request(self, {
      method = 'get',
      path   = EntitySet,
      params = { fetchXml = T.query },
      headers = T.headers,
      live    = T.live,
   })

   if not Result then return nil, Err end

   if Result.simulated then
      return Result
   end

   -- Dynamics returns { value = [ ... ] } for collection queries.
   if type(Result.value) == 'table' then
      return Result.value
   end

   -- Single record or unexpected shape: wrap in a table for consistency.
   return { Result }
end

-- Force a token exchange. Not normally needed, since requests authenticate on
-- demand; useful to validate credentials at startup.
function Client:authenticate()
   return Auth.authenticate(self)
end

-- Format today's date as YYYY-MM-DD for FetchXML conditions.
--
-- Kept as a client method for convenience, so scripts that build dynamic
-- queries can call Crm:formatDate() without importing os.date separately.
function Client:formatDate(Time)
   return os.date('%Y-%m-%d', Time or os.time())
end

-- ---------------------------------------------------------------------------
-- Module
-- ---------------------------------------------------------------------------

local M = {}

M.Client = Client

-- Build a client explicitly.
--
--   Url        - base URL of the Dynamics 365 instance (e.g. https://org.crm.dynamics.com/)
--   Username   - Azure AD user for the ROPC grant
--   Password   - the user's password
--   ClientId   - Azure AD app registration client id (optional, uses default if empty)
--   TokenUrl   - Azure AD token endpoint (optional, derived from URL if empty)
--   Timeout    - request timeout in seconds, defaults to 30
--   VerifyTls  - verify the server certificate, defaults to true
--   Live       - perform real requests, defaults to true
function M.new(T)
   T = T or {}

   local BaseUrl = T.Url
   if BaseUrl == nil or BaseUrl == '' then
      error('dynamics_crm.new: Url is required')
   end
   if BaseUrl:sub(-1) ~= '/' then BaseUrl = BaseUrl .. '/' end

   -- The default client id is the well-known Dynamics 365 first-party app.
   local ClientId = T.ClientId
   if not ClientId or ClientId == '' then
      ClientId = '2ad88395-b77d-4561-9441-d0e40824f9bc'
   end

   -- Derive the Azure AD token URL from the base URL if not given explicitly.
   -- Default to the /common/ endpoint which works for multi-tenant apps.
   local TokenUrl = T.TokenUrl
   if not TokenUrl or TokenUrl == '' then
      TokenUrl = 'https://login.microsoftonline.com/common/oauth2/token'
   end

   local Instance = setmetatable({}, Client)
   Instance.base_url     = BaseUrl
   Instance.username     = T.Username or ''
   Instance.password     = T.Password or ''
   Instance.client_id    = ClientId
   Instance.token_url    = TokenUrl
   Instance.resource_url = BaseUrl
   Instance.timeout      = tonumber(T.Timeout) or DEFAULT_TIMEOUT
   Instance.verify_tls   = T.VerifyTls ~= false
   Instance.live         = T.Live ~= false

   -- Scoping the cached token by credential and environment.
   Instance.cache_key = Instance.username .. '@' .. Instance.base_url

   return Instance
end

-- Build a client from the current node's own configuration fields.
--
-- Returns the client and the raw config table, so a script can read its own
-- additional fields without a second linkiir.config.node() call:
--
--    local Crm, Config = DynamicsCrm.fromNodeConfig()
--    local Query = Config['FetchXML Query']
function M.fromNodeConfig()
   local Config = linkiir.config.node()

   local Instance = M.new{
      Url       = Config['URL'],
      Username  = Config['Username'],
      Password  = Config['Password'],
      VerifyTls = Config['Verify TLS'],
      Live      = Config['Live Mode'],
   }

   return Instance, Config
end

return M

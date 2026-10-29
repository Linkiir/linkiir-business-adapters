-- ---------------------------------------------------------------------------
-- dynamics_crm_auth - obtains a Dynamics 365 access token
--
-- Dynamics 365 Online uses Azure AD OAuth 2.0 with a Resource Owner Password
-- Credentials (ROPC) grant. The token endpoint is the Azure AD v1 endpoint
-- for the tenant, and the request posts:
--
--    grant_type=password
--    username=<user>
--    password=<pass>
--    client_id=<app registration client id>
--    resource=<CRM base URL>
--
-- When no explicit Client ID is configured, the well-known Dynamics 365 first-
-- party application ID is used as a default, which is sufficient for ROPC
-- flows in many tenants.
--
-- Callers use M.ensure, which authenticates only when there is no usable token
-- cached. M.authenticate forces a fresh exchange.
-- ---------------------------------------------------------------------------

local TokenCache = require 'dynamics_crm_token'

local M = {}

-- Microsoft's first-party Dynamics 365 client id (used when none is configured).
local DEFAULT_CLIENT_ID = '2ad88395-b77d-4561-9441-d0e40824f9bc'

-- Used when a token response omits expires_in.
local DEFAULT_TOKEN_LIFETIME = 3600

-- Percent-encode a flat table as application/x-www-form-urlencoded.
--
-- The token endpoint expects its grant fields in the request body. Passing them
-- as `params` to linkiir.link.web.post would put them in the query string,
-- where the endpoint does not look for them.
local function formEncode(Params)
   local Parts = {}
   for Key, Value in pairs(Params) do
      Parts[#Parts + 1] = linkiir.codec.uri.encode(tostring(Key))
         .. '=' .. linkiir.codec.uri.encode(tostring(Value))
   end
   return table.concat(Parts, '&')
end

-- Exchange username/password credentials for a bearer token.
-- Returns the token, or nil plus { code=, message= }.
function M.authenticate(Client)
   if not Client.username or Client.username == '' then
      return nil, {
         code    = 'CONFIG_ERROR',
         message = 'Username is not configured on this node',
      }
   end
   if not Client.password or Client.password == '' then
      return nil, {
         code    = 'CONFIG_ERROR',
         message = 'Password is not configured on this node',
      }
   end

   local TokenUrl = Client.token_url

   local Body = {
      grant_type = 'password',
      username   = Client.username,
      password   = Client.password,
      client_id  = Client.client_id,
      resource   = Client.resource_url,
   }

   local Response, WebErr = linkiir.link.web.post{
      url = TokenUrl,
      headers = {
         ['Content-Type'] = 'application/x-www-form-urlencoded',
         ['Accept']       = 'application/json',
      },
      body      = formEncode(Body),
      timeout   = Client.timeout,
      verifyTls = Client.verify_tls,
      live      = true,
   }

   if not Response then
      return nil, WebErr or {
         code    = 'AUTH_FAILED',
         message = 'token request to ' .. TokenUrl .. ' failed',
      }
   end

   if Response.code ~= 200 then
      return nil, {
         code    = 'AUTH_FAILED',
         message = 'Dynamics token endpoint returned HTTP ' .. tostring(Response.code),
         body    = Response.body,
      }
   end

   local Ok, Auth = pcall(linkiir.json.parse, Response.body)
   if not Ok or type(Auth) ~= 'table' or not Auth.access_token then
      return nil, {
         code    = 'AUTH_FAILED',
         message = 'token response was not JSON containing an access_token',
         body    = Response.body,
      }
   end

   Client.key        = Auth.access_token
   Client.key_expiry = os.time() + (tonumber(Auth.expires_in) or DEFAULT_TOKEN_LIFETIME)
   TokenCache.put(Client.cache_key, Client.key, Client.key_expiry)

   return Client.key
end

-- Return a usable token, authenticating only if needed.
--
-- Checks the token already on the client, then the shared cache, then falls
-- back to a fresh password grant.
function M.ensure(Client)
   if Client.key and Client.key_expiry
      and Client.key_expiry - TokenCache.EXPIRY_SKEW > os.time() then
      return Client.key
   end

   local Cached = TokenCache.get(Client.cache_key)
   if Cached then
      Client.key        = Cached.token
      Client.key_expiry = Cached.expires_at
      return Client.key
   end

   return M.authenticate(Client)
end

return M

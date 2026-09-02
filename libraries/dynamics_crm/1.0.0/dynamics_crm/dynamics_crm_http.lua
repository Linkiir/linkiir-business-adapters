-- ---------------------------------------------------------------------------
-- dynamics_crm_http - the request path every CRM call goes through
--
-- Attaches the bearer token, builds the request URL, sends the request, and
-- turns whatever Dynamics returns into one predictable pair:
--
--    Result        - the parsed response data (table of entity records)
--    nil, Err      - Err is { code=, message= } plus optional context
--
-- Dynamics 365 Web API returns OData JSON. A FetchXML query returns a
-- { value = [ ... ] } object where value is the array of matching records.
-- ---------------------------------------------------------------------------

local Auth = require 'dynamics_crm_auth'

local M = {}

-- Merge caller headers with the ones this module controls. Authorization is
-- applied last so a caller cannot accidentally replace it.
local function buildHeaders(CallerHeaders, Token)
   local Headers = {}
   for Key, Value in pairs(CallerHeaders or {}) do
      Headers[Key] = Value
   end
   Headers['Accept']        = Headers['Accept'] or 'application/json'
   Headers['OData-MaxVersion'] = '4.0'
   Headers['OData-Version']    = '4.0'
   Headers['Authorization'] = 'Bearer ' .. Token
   return Headers
end

-- Parse a response body and classify it as success or failure.
local function readBody(Response)
   local Ok, Parsed = pcall(linkiir.json.parse, Response.body)
   if not Ok then
      return nil, {
         code      = 'PARSE_ERROR',
         message   = 'Dynamics response was not valid JSON',
         http_code = Response.code,
         body      = Response.body,
      }
   end

   if Response.code < 200 or Response.code >= 300 then
      -- Dynamics error responses include an error object with code and message.
      local ErrMsg = 'Dynamics returned HTTP ' .. tostring(Response.code)
      if type(Parsed) == 'table' and type(Parsed.error) == 'table' then
         ErrMsg = Parsed.error.message or ErrMsg
      end
      return nil, {
         code      = 'HTTP_' .. tostring(Response.code),
         message   = ErrMsg,
         http_code = Response.code,
         body      = Parsed,
      }
   end

   return Parsed
end

-- Send one request to the Dynamics 365 Web API.
--
--   T.method     - HTTP verb, defaults to 'get'
--   T.path       - path below the base URL, e.g. 'ccx_master_queues'
--   T.params     - query parameters table (for GET requests)
--   T.body       - request body string (for POST/PATCH)
--   T.headers    - extra headers
--   T.live       - overrides the client's live flag for this call
function M.request(Client, T)
   local Token, AuthErr = Auth.ensure(Client)
   if not Token then return nil, AuthErr end

   local Method = tostring(T.method or 'get'):lower()
   local SendRequest = linkiir.link.web[Method]
   if not SendRequest then
      error("dynamics_crm_http.request: unsupported HTTP method '" .. Method .. "'")
   end

   local Headers = buildHeaders(T.headers, Token)

   -- A per-call live flag wins over the client's; both default to true.
   local Live = T.live
   if Live == nil then Live = Client.live end
   if Live == nil then Live = true end

   local Url = Client.base_url .. 'api/data/v9.2/' .. tostring(T.path or '')

   local Request = {
      url       = Url,
      headers   = Headers,
      params    = T.params,
      timeout   = Client.timeout,
      verifyTls = Client.verify_tls,
      live      = Live,
   }

   if T.body then
      Request.body = T.body
      if not Headers['Content-Type'] then
         Headers['Content-Type'] = 'application/json'
      end
   end

   linkiir.log.debug('dynamics_crm ' .. Method:upper() .. ' ' .. Url)

   local Response, WebErr = SendRequest(Request)
   if not Response then
      return nil, WebErr or {
         code    = 'REQUEST_FAILED',
         message = Method:upper() .. ' ' .. Url .. ' failed',
      }
   end

   -- With live = false nothing was sent, so there is no body to interpret.
   if Response.simulated then
      return { simulated = true, code = 0 }
   end

   if Response.body == nil or Response.body == '' then
      if Response.code >= 200 and Response.code < 300 then
         return { code = Response.code }
      end
      return nil, {
         code    = 'HTTP_' .. tostring(Response.code),
         message = 'Dynamics returned HTTP ' .. tostring(Response.code) .. ' with an empty body',
      }
   end

   return readBody(Response)
end

return M

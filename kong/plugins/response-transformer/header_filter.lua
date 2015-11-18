local utils = require "kong.tools.utils"
local stringy = require "stringy"

local table_insert = table.insert
local unpack = unpack
local type = type

local APPLICATION_JSON = "application/json"
local CONTENT_TYPE = "content-type"
local CONTENT_LENGTH = "content-length"

local ok, new_tab = pcall(require, "table.new")
if not ok then
  new_tab = function (narr, nrec) return {} end
end

local _M = {}

local function iter(config_array)
  return function(config_array, i, previous_header_name, previous_header_value)
    i = i + 1
    local header_to_test = config_array[i]
    if header_to_test == nil then -- n + 1
      return nil
    end
    local header_to_test_name, header_to_test_value = unpack(stringy.split(header_to_test, ":"))
    return i, header_to_test_name, header_to_test_value  
  end, config_array, 0
end

local function append_value(current_value, value)
  local current_value_type = type(current_value)
 
  if current_value_type  == "string" then
    return {current_value, value}
  elseif current_value_type  == "table" then
    table_insert(current_value, value)
    return current_value  
  else
    return {value} 
  end
end

local function is_json_body(content_type)
  if content_type then
    content_type = stringy.strip(content_type):lower()
    return stringy.startswith(content_type, APPLICATION_JSON)
  end
  return false
end

---
--   # Example:
--   ngx.headers = header_filter.transform_headers(conf, ngx.headers)
-- We run transformations in following order: remove, replace, add, append. 
-- @param[type=table] conf Plugin configuration.
-- @param[type=table] ngx_headers Table of headers, that should be `ngx.headers`
-- @treturn table A table containing the new headers.
function _M.transform_headers(conf, ngx_headers)
  local inspect = require "inspect"
  local are_headers_transformed = false
  
  for _, header_name, header_value in iter(conf.remove.headers) do
      ngx_headers[header_name] = nil
      are_headers_transformed = true
  end
  
  for _, header_name, header_value in iter(conf.replace.headers) do
    if ngx_headers[header_name] ~= nil then
      ngx_headers[header_name] = header_value
      are_headers_transformed = true
    end
  end
  
  for _, header_name, header_value in iter(conf.add.headers) do
    if ngx_headers[header_name] == nil then
      ngx_headers[header_name] = header_value
      are_headers_transformed = true
    end
  end
  
  for _, header_name, header_value in iter(conf.append.headers) do
    ngx_headers[header_name] = append_value(ngx_headers[header_name], header_value)
    are_headers_transformed = true
  end
  
  -- Removing the header because the body is going to change
  if conf.add.json and is_json_body(ngx_headers[CONTENT_TYPE]) and are_headers_transformed then
    ngx_headers[CONTENT_LENGTH] = nil
  end
end

return _M

local _M = {}

function _M.load(configuration, events_handler)
  local DaoFactory = require("kong.dao."..configuration.database..".factory")
  return DaoFactory(configuration.dao_config, configuration.plugins_available, events_handler)
end

return _M

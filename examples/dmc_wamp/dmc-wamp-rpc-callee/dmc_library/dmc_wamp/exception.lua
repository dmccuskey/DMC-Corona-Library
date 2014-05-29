

--====================================================================--
-- Imports

local Objects = require( dmc_lib_func.find('dmc_objects') )
local Error = require( dmc_lib_func.find('lua_error') )

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom


--====================================================================--
-- Protocol Error Class
--====================================================================--

local ProtocolError = inheritsFrom( Error )
ProtocolError.NAME = "Protocol Error"

local function ProtocolErrorFactory( message )
	return ProtocolError:new( { message=message })
end




--====================================================================--
-- Exception Facade
--====================================================================--

return {
	ProtocolError=ProtocolError,
	ProtocolErrorFactory=ProtocolErrorFactory
}

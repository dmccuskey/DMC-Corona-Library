

--====================================================================--
-- Imports

local Objects = require( dmc_lib_func.find('dmc_objects') )

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase


--====================================================================--
-- Support Functions

-- https://gist.github.com/cwarden/1207556

local function try( funcs )
	local try_f, catch_f, finally_f = funcs[1], funcs[2], funcs[3]
	local status, result = pcall(try_f)
	if not status and catch_f then
		catch_f(result)
	end
	if finally_f then finally_f() end
	return result
end

local function catch(f)
	return f[1]
end

local function finally(f)
	return f[1]
end



--====================================================================--
-- Error Class
--====================================================================--

local Error = inheritsFrom( ObjectBase )
Error.NAME = "Error Base"

function Error:_init( params )
	-- print( "Message:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	if self.is_intermediate then return end

	self.message = params.message or "ERROR"
	self.traceback = debug.traceback()

	local mt = getmetatable( self )
	mt.__tostring = function(e) return "ERROR: "..e.message end

end




--====================================================================--
-- Error Facade
--====================================================================--

_G.try = try
_G.catch = catch
_G.finally = finally

return Error

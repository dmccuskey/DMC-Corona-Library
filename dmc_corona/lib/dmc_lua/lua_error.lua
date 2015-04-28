--====================================================================--
-- lua_error.lua
--
-- Documentation:
-- * http://github.com/dmccuskey/lua-error
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014-2015 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Lua Library : Lua Error
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.3.0"



--====================================================================--
--== Imports


local Class = require 'lua_class'


-- Check imports
-- TODO: work on this
assert( Class, "lua_error: requires lua_class" )
if checkModule then checkModule( Class, '1.1.2' ) end



--====================================================================--
--== Setup, Constants


-- none



--====================================================================--
--== Support Functions


-- based on https://gist.github.com/cwarden/1207556

local function try( funcs )
	local try_f, catch_f, finally_f = funcs[1], funcs[2], funcs[3]
	assert( try_f, "lua-error: missing function for try()" )
	--==--
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
--== Error Base Class
--====================================================================--


local Error = newClass( nil, { name="Error Instance" } )

--== Class Constants ==--

Error.__version = VERSION

Error.DEFAULT_PREFIX = "ERROR: "
Error.DEFAULT_MESSAGE = "There was an error"


function Error:__new__( message, params )
	message = message or self.DEFAULT_MESSAGE
	params = params or {}
	params.prefix = params.prefix or self.DEFAULT_PREFIX
	--==--

	-- guard subclasses
	if self.is_class then return end

	-- save args
	self.prefix = params.prefix
	self.message = message
	self.traceback = debug.traceback()

end


-- must return a string
--
function Error:__tostring__( id )
	return table.concat( { self.prefix, self.message, "\n", self.traceback } )
end




--====================================================================--
--== Error API Setup
--====================================================================--

-- globals
_G.try = try
_G.catch = catch
_G.finally = finally



return Error

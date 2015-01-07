--====================================================================--
-- lua_error.lua
--
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_error.lua
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014 David McCuskey. All Rights Reserved.

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
-- DMC Lua Library : Lua Error
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.1"


--====================================================================--
-- Imports

local Objects = require 'lua_objects'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase


--====================================================================--
-- Support Functions

-- based on https://gist.github.com/cwarden/1207556

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
-- Error Base Class
--====================================================================--


local Error = inheritsFrom( ObjectBase )
Error.NAME = "Error Instance"

function Error:_init( params )
	-- print( "Error:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	if self.is_intermediate then return end

	self.prefix = params.prefix or "ERROR: "
	self.message = params.message or "there was an error"
	self.traceback = debug.traceback()

	local mt = getmetatable( self )
	mt.__tostring = function(e)
		return table.concat({self.prefix,e.message,"\n",e.traceback})
	end

end



--====================================================================--
--== Error API Setup
--====================================================================--

-- globals
_G.try = try
_G.catch = catch
_G.finally = finally



return Error

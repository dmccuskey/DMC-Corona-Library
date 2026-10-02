--====================================================================--
-- lua_error.lua
--
-- Documentation:
-- * https://github.com/dmccuskey/lua-error
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

local VERSION = "0.4.1"



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


local unpack = unpack or table.unpack

-- marks for catch{} and finally{}, so try() knows each by its kind, not its place
local CATCH, FINALLY = {}, {}

-- based on https://gist.github.com/cwarden/1207556

local function pack( ... )
	return { n=select( '#', ... ), ... }
end

-- returns the function in a catch{} or finally{} mark, or a plain function
-- in the given place (2 for a catch, 3 for a finally)
local function findPart( funcs, kind, place )
	for i=2,3 do
		local f = funcs[i]
		if type(f)=='table' and f.kind==kind then return f.func end
	end
	local f = funcs[place]
	if type(f)=='function' then return f end
end

-- runs the function; on an error, runs the catch, or raises the error again
-- if there is none; runs the finally last in every case, then raises an
-- error the catch raised, or returns the values of the function or the catch
--
local function try( funcs )
	local try_f = funcs[1]
	local catch_f = findPart( funcs, CATCH, 2 )
	local finally_f = findPart( funcs, FINALLY, 3 )
	assert( type(try_f)=='function', "lua-error: missing function for try()" )
	--==--
	local result = pack( pcall( try_f ) )
	if not result[1] and catch_f then
		-- protect the catch only when a finally must run after it
		if not finally_f then return catch_f( result[2] ) end
		result = pack( pcall( catch_f, result[2] ) )
	end
	if finally_f then finally_f() end
	if not result[1] then error( result[2], 0 ) end
	return unpack( result, 2, result.n )
end

local function catch( f )
	return { kind=CATCH, func=f[1] }
end

local function finally( f )
	return { kind=FINALLY, func=f[1] }
end

-- whether a stack level is lua-error's or lua-class's own code, or a level
-- Lua 5.1 lost to a tail call (lua-class returns its constructors as such)
local function isLibraryLevel( info )
	local src = info.short_src
	return info.what=='C' or info.what=='tail' or src:find( 'lua_error.lua', 1, true )
		or src:find( 'lua_class.lua', 1, true )
end

-- the traceback from where an error object was created: skips the levels of
-- lua-error, lua-class, and the __new__() constructors of the object's classes
--
local function creationTraceback( obj )
	local ctors = {}
	local function addCtors( classes )
		for _, cls in ipairs( classes or {} ) do
			local f = rawget( cls, '__new__' )
			if f then ctors[f]=true end
			addCtors( rawget( cls, '__parents' ) )
		end
	end
	addCtors( rawget( obj, '__parents' ) )

	local level = 2 -- the caller
	while true do
		local info = debug.getinfo( level, 'Sf' )
		if not info then return debug.traceback( "", 2 ):sub( 2 ) end
		if not ( isLibraryLevel( info ) or ctors[info.func] ) then break end
		level = level + 1
	end
	-- drop the newline traceback() puts after the (empty) message
	return debug.traceback( "", level ):sub( 2 )
end



--====================================================================--
--== Error Base Class
--====================================================================--


local Error = Class.newClass( nil, { name="Error Instance" } )

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
	self.traceback = creationTraceback( self )

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

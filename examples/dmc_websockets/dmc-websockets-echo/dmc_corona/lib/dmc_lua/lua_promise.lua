--====================================================================--
-- lua_promise.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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
--== DMC Lua Library: Lua Promise
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.1"



--====================================================================--
--== Imports


local Objects = require 'lua_objects'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local Class = Objects.Class

-- local control of development functionality
local LOCAL_DEBUG = false

local tinsert = table.insert

local Promise, Deferred, Failure -- forward declaration



--====================================================================--
--== Support Functions


-- implemented from Twisted defer.py
-- https://twistedmatrix.com/documents/13.1.0/api/twisted.internet.defer.html

local function succeed( result )
	local d = Deferred:new()
	d:callback( result )
	return d
end

local function fail( result )
	local d = Deferred:new()
	d:errback( result )
	return d
end

local function maybeDeferred( func, args, kwargs )
	local result = func( args, kwargs )
	local is_obj = type(result)=='table' and result.isa ~= nil

	if is_obj and result:isa( Deferred ) then
		return result

	elseif is_obj and result:isa( Failure ) then
		return fail( result )

	else
		return succeed( result )
	end

	return nil
end



--====================================================================--
--== Promise Class
--====================================================================--


Promise = newClass( nil, { name="Lua Promise" } )

--== State Constants ==--

Promise.STATE_PENDING = 'pending'
Promise.STATE_RESOLVED = 'resolved'
Promise.STATE_REJECTED = 'rejected'


--======================================================--
-- Start: Setup Lua Objects

function Promise:__new__( params )
	-- print( "Promise:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self._state = Promise.STATE_PENDING
	self._done_cbs = {}
	self._fail_cbs = {}
	self._progress_cbs = {}

	self._result = nil
	self._reason = nil

end

-- END: Setup Lua Objects
--======================================================--


--====================================================================--
--== Public Methods


function Promise.__getters:state()
	return self._state
end


function Promise:resolve( ... )
	-- print( "Promise:resolve" )
	self._state = Promise.STATE_RESOLVED
	self._result = {...}
	self:_execute( self._done_cbs, ... )
end

function Promise:reject( ... )
	-- print( "Promise:reject" )
	self._state = Promise.STATE_REJECTED
	self._reason = {...}
	self:_execute( self._fail_cbs, ... )
end


function Promise:done( callback )
	-- print( "Promise:done" )
	if self._state == Promise.STATE_RESOLVED then
		callback( unpack( self._result ) )
	else
		self:_addCallback( self._done_cbs, callback )
	end
end

function Promise:progress( ... )
	error( "Promise:progress: not yet implemented" )
end

function Promise:fail( errback )
	-- print( "Promise:fail" )
	if self._state == Promise.STATE_REJECTED then
		errback( unpack( self._reason ) )
	else
		self:_addCallback( self._fail_cbs, errback )
	end
end



--====================================================================--
--== Private Methods


function Promise:_addCallback( list, func )
	tinsert( list, #list+1, func )
end

function Promise:_execute( list, ... )
	-- print("Promise:_execute")
	for i=1,#list do
		list[i]( ... )
	end
end




--====================================================================--
--== Deferred Class
--====================================================================--


Deferred = newClass( nil, { name="Lua Deferred" } )


--======================================================--
-- Start: Setup Lua Objects

function Deferred:__new__( params )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self._promise = Promise:new()
end

-- END: Setup Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


function Deferred.__getters:promise()
	return self._promise
end


function Deferred:callback( ... )
	self._promise:resolve( ... )
end
function Deferred:notify( ... )
	self._promise:progress( ... )
end
function Deferred:errback( ... )
	self._promise:reject( ... )
end

function Deferred:addCallbacks( callback, errback )
	local promise = self._promise
	if callback then promise:done( callback ) end
	if errback then promise:fail( errback ) end
end



--====================================================================--
--== Promise Module Facade
--====================================================================--


return {
	__version=VERSION,

	Promise=Promise,
	Deferred=Deferred,
	maybeDeferred=maybeDeferred
}

--====================================================================--
-- dmc_wamp/future_mix.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014-2015 David McCuskey

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
--== DMC Corona Library : DMC WAMP Future Mix
--====================================================================--


--[[
WAMP support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local Promise = require 'lib.dmc_lua.lua_promise'



--====================================================================--
--== Setup, Constants


local Deferred, maybeDeferred = Promise.Deferred, Promise.maybeDeferred

local Future



--====================================================================--
--== Support Functions


-- -- create general output string
-- function outStr( msg )
-- 	return "Future (debug) :: " .. tostring( msg )
-- end

-- -- create general error string
-- function errStr( msg )
-- 	return "\n\nERROR: Future :: " .. tostring( msg ) .. "\n\n"
-- end



function _patch( obj )

	obj = obj or {}

	-- add properties
	Future.__init__( obj )

	-- add methods
	obj._create_future = Future._create_future
	obj._as_future = Future._as_future
	obj._resolve_future = Future._resolve_future
	obj._reject_future = Future._reject_future
	obj._add_future_callbacks = Future._add_future_callbacks
	obj._gather_futures = Future._gather_futures

	obj.setDebug = Future.setDebug

	return obj
end


--====================================================================--
--== Future Mixin
--====================================================================--


Future = {}

Future.__debug = false


--======================================================--
-- Start: Mixin Setup for Lua Objects

function Future.__init__( self, params )
	-- print( "Future.__init__" )
	params = params or {}
	--==--
	self.__debug_on = params.debug_on == nil and false or params.debug_on
end

function Future.__undoInit__( self )
	-- print( "Future.__undoInit__" )
	self.__debug_on = nil
end

-- END: Mixin Setup for Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


function Future._create_future( self )
	return Deferred:new()
end

function Future._as_future( self, func, args, kwargs )
	-- print( "Future._as_future", self, func, args, kwargs )
	return maybeDeferred( func, args, kwargs )
end

function Future._resolve_future( self, future, value )
	return future:callback( value )
end

function Future._reject_future( self, future, value )
	return future:errback( value )
end

function Future._add_future_callbacks( self, future, callback, errback )
	-- print( "Future._add_future_callbacks", self, future, callback, errback )
	return future:addCallbacks( callback, errback )
end

function Future._gather_futures( self, futures, consume_exceptions )
	consume_exceptions = consume_exceptions or true

	return DeferredList( {futures}, {consume_errors=consume_exceptions} )
end


function Future._setDebug( self, value )
	self.__debug_on = value
end



--====================================================================--
--== Future Facade
--====================================================================--


return {
	FutureMix=Future,

	patch =_patch
}


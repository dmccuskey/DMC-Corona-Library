--====================================================================--
-- dmc_wamp/future_mix.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_wamp.lua
--====================================================================--

--[[

Copyright (C) 2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]


--====================================================================--
-- DMC Corona Library : Future Mix
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local Promise = require 'lua_promise'


--====================================================================--
-- Setup, Constants

local Deferred, maybeDeferred = Promise.Deferred, Promise.maybeDeferred



--====================================================================--
-- Future Mix Container
--====================================================================--


local FutureMixin = {}

FutureMixin._DEBUG = false


--====================================================================--
-- Public Functions

function FutureMixin.create_future( self )
	return Deferred:new()
end
function FutureMixin.as_future( self, func, args, kwargs )
	return maybeDeferred( func, args, kwargs )
end
function FutureMixin.resolve_future( self, future, value )
	return future:callback( value )
end
function FutureMixin.reject_future( self, future, value )
	return future:errback( value )
end
function FutureMixin.add_future_callbacks( self, future, callback, errback )
	print( self, future, callback, errback )
	return future:addCallbacks( callback, errback )
end
function FutureMixin.gather_futures( self, futures, consume_exceptions )
	consume_exceptions = consume_exceptions or true

	return DeferredList( {futures}, {consume_errors=consume_exceptions} )
end

--== Facade API Methods ==--

function FutureMixin._setDebug( value )
	States._DEBUG = value
end

function FutureMixin._mixin( obj )
	if FutureMixin._DEBUG then
		print( "WAMP FutureMixin::mixin: ", obj.NAME )
	end

	obj = obj or {}

	-- add methods
	obj._create_future = FutureMixin.create_future
	obj._as_future = FutureMixin.as_future
	obj._resolve_future = FutureMixin.resolve_future
	obj._reject_future = FutureMixin.reject_future
	obj._add_future_callbacks = FutureMixin.add_future_callbacks
	obj._gather_futures = FutureMixin.gather_futures

	return obj
end




--====================================================================--
-- Future Facade
--====================================================================--


return {
	setDebug = FutureMixin._setDebug,
	mixin = FutureMixin._mixin
}


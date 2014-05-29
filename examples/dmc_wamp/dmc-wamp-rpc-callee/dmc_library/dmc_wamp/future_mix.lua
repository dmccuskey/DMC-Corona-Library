


--====================================================================--
-- Imports

-- local Promise = require 'lua_promise'
local Promises = require( dmc_lib_func.find('lua_promise') )
local Deferred, maybeDeferred = Promises.Deferred, Promises.maybeDeferred


--====================================================================--
-- Setup, Constants

local FutureMixin = {}

FutureMixin._DEBUG = false

--====================================================================--
-- Setup, Constants


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
-- Future Facade Object
--====================================================================--

local FutureFacade = {}

FutureFacade.setDebug = FutureMixin._setDebug
FutureFacade.mixin = FutureMixin._mixin

return FutureFacade


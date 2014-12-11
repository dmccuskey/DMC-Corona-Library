--====================================================================--
-- dmc_wamp.lua
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
-- DMC Corona Library : DMC WAMP
--====================================================================--

--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


--====================================================================--
-- Support Functions

local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end


--====================================================================--
-- Configuration

local dmc_lib_data, dmc_lib_info

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_corona_boot" ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_library



--====================================================================--
-- DMC WAMP
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_wamp = dmc_lib_data.dmc_wamp or {}

local DMC_WAMP_DEFAULTS = {
	debug_active=false,
}

local dmc_wamp_data = Utils.extend( dmc_lib_data.dmc_wamp, DMC_WAMP_DEFAULTS )


--====================================================================--
-- Imports

local Objects = require 'lua_objects'
local States = require 'lua_states'
local Utils = require 'lua_utils'

local WebSocket = require 'dmc_websockets'

local Error = require 'dmc_wamp.exception'
local SerializerFactory = require 'dmc_wamp.serializer'
local wprotocol = require 'dmc_wamp.protocol'



--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom

-- local control of development functionality
local LOCAL_DEBUG = false



--====================================================================--
-- Wamp Class
--====================================================================--


local Wamp = inheritsFrom( WebSocket )
Wamp.NAME = "Wamp Class"

--== Event Constants

Wamp.EVENT = 'wamp_event'

Wamp.ONOPEN = 'onopen'
Wamp.ONCONNECT = 'onconnect'
Wamp.ONDISCONNECT = 'ondisconnect'
-- Wamp.ONCLOSE = 'onclose'


--====================================================================--
--== Start: Setup DMC Objects

function Wamp:_init( params )
	-- print( "Wamp:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	if not self.is_intermediate then
		assert( params.realm, "Wamp: requires parameter 'realm'" )
	end

	--== Create Properties ==--

	self._realm = params.realm
	self._protocols = params.protocols or { 'wamp.2.json' }

	--== Object References ==--

	self._session = nil -- a WAMP session object
	self._serializer = nil -- a WAMP session object

end

--== END: Setup DMC Objects
--====================================================================--


--====================================================================--
--== Public Methods

-- is_connected, getter, boolean
--
function Wamp.__getters:is_connected()
	-- print( "Wamp.__getters:is_connected" )
	return ( self._session ~= nil )
end


-- call()
-- @param procedure string name of RPC to invoke
-- @param params table of options:
-- args - array
-- kwargs - table
-- onResult - callback
-- onProgress - callback
-- onError - callback
function Wamp:call( procedure, params )
	-- print( "Wamp:call", procedure )
	params = params or {}
	--==--

	local onError = params.onError

	params.onError = function( event )
		-- print( "Wamp:call, on error")
		if onError then onError( event ) end
	end

	return self._session:call( procedure, params )
end

-- register()
-- @param handler callback/object to handle Calls
-- @param params table of various parameters
--
function Wamp:register( handler, params )
	-- print( "Wamp:register", handler )
	if params.pkeys or params.disclose_caller then
		params.options = Types.RegisterOptions:new( params )
	end
	return self._session:register( handler, params )
end

-- unregister()
-- @param handler callback/object to handle Calls (same item as register())
-- @param params table of various parameters
--
function Wamp:unregister( handler, params )
	-- print( "Wamp:unregister", handler )

	try{
		function()
			self._session:unregister( handler, params )
		end,

		catch{
			function(e)
				if type(e)=='string' then
					error( e )
				elseif e:isa( Error.ProtocolError ) then
					self:_bailout{
						code=WebSocket.CLOSE_STATUS_CODE_PROTOCOL_ERROR,
						reason="WAMP Protocol Error"
					}
				else
					self:_bailout{
						code=WebSocket.CLOSE_STATUS_CODE_INTERNAL_ERROR,
						reason="WAMP Internal Error ({})"
					}
				end
			end
		}
	}

end


-- publish()
-- @param topic string of "channel" to publish to
-- @param params table of various parameters
-- args
-- kwargs
-- onSuccess callback
-- onError callback
-- options table of options
-- acknowledge boolean
--
function Wamp:publish( topic, params )
	-- print( "Wamp:publish", topic )

	try{
		function()
			self._session:publish( topic, params )
		end,

		catch{
			function(e)
				if type(e)=='string' then
					error( e )
				elseif e:isa( Error.ProtocolError ) then
					print( e.traceback )
					self:_bailout{
						code=WebSocket.CLOSE_STATUS_CODE_PROTOCOL_ERROR,
						reason="WAMP Protocol Error"
					}
				else
					print( e.traceback )
					self:_bailout{
						code=WebSocket.CLOSE_STATUS_CODE_INTERNAL_ERROR,
						reason="WAMP Internal Error ({})"
					}
				end
			end
		}
	}

end

-- subscribe()
-- @param topic string of "channel" to subscribe to
-- @param handler function callback
--
function Wamp:subscribe( topic, handler )
	-- print( "Wamp:subscribe", topic )
	return self._session:subscribe( topic, handler )
end

-- unsubscribe()
-- @param topic string of "channel" to subscribe to
-- @param handler function callback, same as in subscribe()
--
function Wamp:unsubscribe( topic, handler )
	-- print( "Wamp:unsubscribe", topic )
	return self._session:unsubscribe( topic, handler )
end


function Wamp:send( msg )
	-- print( "Wamp:send", msg.TYPE )
	-- params = params or {}
	--==--
	local bytes, is_binary = self._serializer:serialize( msg )

	if LOCAL_DEBUG then print( 'sending', bytes ) end

	self:superCall( 'send', bytes, { type=is_binary } )
end

function Wamp:leave( reason, message )
	-- print( "Wamp:leave" )
	local p = {
		reason=reason,
		log_message=message
	}
	self._session:leave( p )
end

function Wamp:close( reason, message )
	-- print( "Wamp:close" )
	self:_wamp_close( reason, message )
	self:superCall( 'close' )
end


--====================================================================--
--== Private Methods

function Wamp:_wamp_close( message, was_clean )
	-- print( "Wamp:_wamp_close" )
	local had_session = ( self._session ~= nil )

	if self._session then
		self._session:onClose( message, was_clean )
		self._session = nil
	end

	if had_session then
		self:dispatchEvent( Wamp.ONDISCONNECT )
	end
end


--== Events

-- coming from websockets
function Wamp:_onOpen()
	-- print( "Wamp:_onOpen" )

	-- TODO: match with protocol
	self._serializer = SerializerFactory.create( 'json' )

	self._session = wprotocol.Session:new( { realm=self._realm })
	self._session_f = self:createCallback( self._wampSessionEvent_handler )
	self._session:addEventListener( self._session.EVENT, self._session_f )

	self._session:onOpen( { transport=self } )
end


-- coming from websockets
function Wamp:_onMessage( message )
	-- print( "Wamp:_onMessage", message )

	try{
		function()
			local msg = self._serializer:unserialize( message.data )
			self._session:onMessage( msg, onError )
		end,

		catch{
			function(e)
				if type(e)=='string' then
					error( e )
				elseif e:isa( Error.ProtocolError ) then
					print( e.traceback )
					self:_bailout{
						code=WebSocket.CLOSE_STATUS_CODE_PROTOCOL_ERROR,
						reason="WAMP Protocol Error"
					}
				else
					print( e.traceback )
					self:_bailout{
						code=WebSocket.CLOSE_STATUS_CODE_INTERNAL_ERROR,
						reason="WAMP Internal Error ({})"
					}
				end
			end
		}
	}

end

-- coming from websockets
function Wamp:_onClose( message, was_clean )
	-- print( "Wamp:_onClose" )
	self:_wamp_close( reason, message )
end


--====================================================================--
--== Event Handlers

function Wamp:_wampSessionEvent_handler( event )
	-- print( "Wamp:_wampSessionEvent_handler: ", event.type )
	local e_type = event.type
	local session = event.target

	if e_type == session.ONJOIN then
		self:dispatchEvent( Wamp.ONCONNECT )
	end

end




return Wamp

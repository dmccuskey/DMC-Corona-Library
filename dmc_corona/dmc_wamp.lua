--====================================================================--
-- dmc_corona/dmc_wamp.lua
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
--== DMC Corona Library : DMC WAMP
--====================================================================--


--[[
WAMP support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Support Functions


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
--== Configuration


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona



--====================================================================--
--== DMC WAMP
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_wamp = dmc_lib_data.dmc_wamp or {}

local DMC_WAMP_DEFAULTS = {
	debug_active=false,
}

local dmc_wamp_data = Utils.extend( dmc_lib_data.dmc_wamp, DMC_WAMP_DEFAULTS )



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local LuaStatesMixin = require 'lib.dmc_lua.lua_states_mix'
local Utils = require 'dmc_utils'
local WebSocket = require 'dmc_websockets'

local WError = require 'dmc_wamp.exception'
local WSerializerFactory = require 'dmc_wamp.serializer'
local WProtocol = require 'dmc_wamp.protocol'
local WTypes = require 'dmc_wamp.types'



--====================================================================--
--== Setup, Constants


local StatesMix = LuaStatesMixin.StatesMix

-- setup some aliases to make code cleaner
local newClass = Objects.newClass

-- local control of development functionality
local LOCAL_DEBUG = dmc_wamp_data.debug_active~=nil and dmc_wamp_data.debug_active or false



--====================================================================--
--== Wamp Class
--====================================================================--


local Wamp = newClass( { WebSocket, StatesMix }, { name="WAMP Connector" } )

--== Class Constants ==--

Wamp.DEFAULT_PROTOCOL = { 'wamp.2.json' }

-- Auth Types

Wamp.AUTH_WAMPCRA = 'wampcra'
Wamp.AUTH_TICKET = 'ticket'

--== Event Constants ==--

Wamp.EVENT = 'wamp_event'

Wamp.ONJOIN = 'wamp_on_join_event'
Wamp.ONCHALLENGE = 'wamp_on_challenge_event'
Wamp.ONCONNECT = 'wamp_on_connect_event'
Wamp.ONDISCONNECT = 'wamp_on_disconnect_event'
-- Wamp.ONCLOSE = 'onclose'

-- these are events from dmc_wamp, not WAMP
-- to make more Corona-esque
Wamp.ONSUBSCRIBED = 'wamp_on_subscribed_event'
Wamp.ONPUBLISH = 'wamp_on_publish_event' -- data event from subscripton
Wamp.ONUNSUBSCRIBED = 'wamp_on_unsubscribed_event'
Wamp.ONPUBLISHED = 'wamp_on_published_event' -- our publish is ok

Wamp.ONRESULT = 'wamp_on_result_event'
Wamp.ONPROGRESS = 'wamp_on_progress_event'


--======================================================--
-- Start: Setup DMC Objects

function Wamp:__init__( params )
	-- print( "Wamp:__init__" )
	params = params or {}
	self:superCall( WebSocket, '__init__', params )
	self:superCall( StatesMix, '__init__', params )
	--==--

	--== Sanity Check ==--

	if self.is_class then return end

	assert( params.realm, "Wamp: requires parameter 'realm'" )
	params.protocols = params.protocols or self.DEFAULT_PROTOCOL

	if type(params.onChallenge)=='function' then
		local f = params.onChallenge
		params.onChallenge = function( args, kwargs )
			local challenge = args[1]
			return f( { session=self, method=challenge.method, extra=challenge.extra, challenge=challenge } )
		end

	end
	--== Create Properties ==--

	self._config = WTypes.ComponentConfig{
		realm=params.realm,
		extra=params.extra,
		authid=params.user_id,
		authmethods=params.auth_methods,
		onchallenge=params.onChallenge
	}

	self._subscriptions = {}

	self._protocols = params.protocols

	--== Object References ==--

	self._session = nil -- a WAMP session object
	self._session_handler = nil -- ref to event handler function

	self._serializer = nil -- a serializer object

end


function Wamp:__initComplete__()
	-- print( "Wamp:__initComplete__" )
	self:superCall( WebSocket, '__initComplete__' )

	self._session_handler = self:createCallback( self._wampSessionEvent_handler )
	self._serializer = WSerializerFactory.create( 'json' )

end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


-- user_id, setter, string
--
function Wamp.__setters:user_id( value )
	-- print( "Wamp.__setters:user_id", value )
	assert( type(value)=='string' )
	--==--
	self._config.authid = value
end

-- auth_methods, setter, table of auth strings
--
function Wamp.__setters:auth_methods( value )
	-- print( "Wamp.__setters:auth_methods", value )
	assert( type(value)=='table' )
	--==--
	self._config.authmethods = value
end




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
function Wamp:call( procedure, handler, params )
	-- print( "Wamp:call", procedure, handler )
	params = params or {}
	params.options = params.options or {}
	assert( type(procedure)=='string', "Wamp:call :: incorrect type for procedure" )
	assert( type(handler)=='function', "Wamp:call :: incorrect type for handler" )
	--==--

	local success_f, progress_f, error_f

	success_f = function( res )
		assert( res and res.isa and res:isa(WTypes.CallResult) )
		if res.results and #res.results==1 and not res.kwresults then
		end
		local evt = {
			is_error=false,
			name=Wamp.EVENT,
			type=Wamp.ONRESULT,
			results=res.results,
			kwresults=res.kwresults,
		}
		-- make it easier to get to single result item
		if res.results and #res.results==1 and not res.kwresults then
			evt.data = res.results[1]
		end
		if handler then handler( evt ) end
	end

	error_f = function( err )
		local evt = {
			is_error=true,
			name=Wamp.EVENT,
			type=Wamp.ONRESULT,
			error=err
		}
		if handler then handler( evt ) end
	end

	progress_f = function( args, kwargs )
		local evt = {
			is_error=false,
			name=Wamp.EVENT,
			type=Wamp.ONPROGRESS,
			args=args,
			kwargs=kwargs
		}
		if handler then handler( evt ) end
	end

	params.options.onProgress = progress_f

	try{
		function()
			local def = self._session:call( procedure, params )
			def:addCallbacks( success_f, error_f )
			return def
		end,

		catch{
			function(e)
				if type(e)=='string' then
					error( e )
				elseif e:isa( WError.ProtocolError ) then
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
				error_f(e)
			end
		}
	}

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
				elseif e:isa( WError.ProtocolError ) then
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
-- options table of options
-- acknowledge boolean
--
function Wamp:publish( topic, params )
	-- print( "Wamp:publish", topic, params )
	params = params or {}
	params.options = params.options or {}
	assert( type(topic)=='string', "Wamp:call :: incorrect type for topic" )
	--==--

	params.options.acknowledge=true -- activate WAMP callbacks

	local success_f, error_f
	local handler = params.callback

	success_f = function( sub )
		local evt = {
			is_error=false,
			name=Wamp.EVENT,
			type=Wamp.ONPUBLISHED
		}
		if handler then handler( evt ) end
	end

	error_f = function( err )
		local evt = {
			is_error=true,
			name=Wamp.EVENT,
			type=Wamp.ONPUBLISHED,
			error=err
		}
		if handler then handler( evt ) end
	end

	try{
		function()
			local def = self._session:publish( topic, params )
			def:addCallbacks( success_f, error_f )
			return def
		end,

		catch{
			function(e)
				if type(e)=='string' then
					error( e )
				elseif e:isa( WError.ProtocolError ) then
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
				error_f(e)
			end
		}
	}

end


function Wamp:_createPubSubKey( topic, handler )
	return topic .. '::' .. tostring( handler )
end

-- subscribe()
-- @param topic string of "channel" to subscribe to
-- @param handler function callback
--
function Wamp:subscribe( topic, handler, params )
	-- print( "Wamp:subscribe", topic, handler )
	params = params or {}
	params.options = params.options or {}
	assert( type(topic)=='string', "Wamp:call :: incorrect type for topic" )
	assert( type(handler)=='function', "Wamp:call :: incorrect type for handler" )
	--==--

	local def, decorate_f, success_f, error_f

	decorate_f = function( evt )
		evt.is_error=false
		evt.name=Wamp.EVENT
		evt.type=Wamp.ONPUBLISH
		handler( evt )
	end

	success_f = function( sub )
		local key = self:_createPubSubKey( topic, handler )
		self._subscriptions[key] = sub

		local evt = {
			is_error=false,
			name=Wamp.EVENT,
			type=Wamp.ONSUBSCRIBED,
			subscription=sub
		}
		handler( evt )
	end

	error_f = function( err )
		local evt = {
			is_error=true,
			name=Wamp.EVENT,
			type=Wamp.ONSUBSCRIBED,
			error=err
		}
		handler( evt )
	end

	def = self._session:subscribe( topic, decorate_f, params )
	def:addCallbacks( success_f, error_f )

	return def
end

-- unsubscribe()
-- @param topic string of "channel" to subscribe to
-- @param handler function callback, same as in subscribe()
--
function Wamp:unsubscribe( topic, handler )
	-- print( "Wamp:unsubscribe", topic, handler )
	assert( type(topic)=='string', "Wamp:call :: incorrect type for topic" )
	assert( type(handler)=='function', "Wamp:call :: incorrect type for handler" )
	--==--

	local key = self:_createPubSubKey( topic, handler )
	local subscription = self._subscriptions[key]

	assert( subscription, "handler not found for topic" )

	local def, success_f, error_f

	success_f = function( sub )
		self._subscriptions[key] = nil
		local evt = {
			is_error=false,
			name=Wamp.EVENT,
			type=Wamp.ONUNSUBSCRIBED,
		}
		handler( evt )
	end

	error_f = function( err )
		local evt = {
			is_error=true,
			name=Wamp.EVENT,
			type=Wamp.ONUNSUBSCRIBED,
			error=err
		}
		handler( evt )
	end

	def = subscription:unsubscribe()
	def:addCallbacks( success_f, error_f )

	return def
end


function Wamp:send( msg )
	-- print( "Wamp:send", msg.MESSAGE_TYPE )
	-- params = params or {}
	--==--
	local bytes, is_binary = self._serializer:serialize( msg )

	if LOCAL_DEBUG then print( 'dmc_wamp:send() :: sending', bytes ) end

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
	-- print( "Wamp:close", reason, message )
	self:_wamp_close( reason, message )
	self:superCall( 'close' )
end



--====================================================================--
--== Private Methods


function Wamp:_wamp_close( reason, message )
	-- print( "Wamp:_wamp_close" )
	local had_session = ( self._session ~= nil )

	if self._session then
		self._session:onClose( message, was_clean )
		self._session = nil
	end

	if had_session then
		self:dispatchEvent( Wamp.ONDISCONNECT, { reason=reason, message=message } )
	end

end


--== Events

-- coming from websockets
function Wamp:_onOpen()
	-- print( "Wamp:_onOpen" )

	local o

	-- TODO: match with protocol
	-- capture errors (eg, one in Role.lua)

	o = WProtocol.Session{ config=self._config }
	o:addEventListener( o.EVENT, self._session_handler )
	self._session = o

	try{
		function()
			self._session:onOpen( { transport=self } )
		end,

		catch{
			function(e)
				if type(e)=='string' then
					error( e )
				elseif e:isa( WError.ProtocolError ) then
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


-- Wamp:_onMessage
-- coming from websockets
-- we get message, and pass to the session
--
function Wamp:_onMessage( message )
	-- print( "Wamp:_onMessage", message )

	try{
		function()
			local msg = self._serializer:unserialize( message.data )
			self._session:onMessage( msg )
		end,

		catch{
			function(e)
				if type(e)=='string' then
					error( e )
				elseif e:isa( WError.ProtocolError ) then
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
function Wamp:_onClose( params )
	-- print( "Wamp:_onClose" )
	self:_wamp_close( params )
end



--====================================================================--
--== Event Handlers


function Wamp:_wampSessionEvent_handler( event )
	-- print( "Wamp:_wampSessionEvent_handler: ", event.type )
	local e_type = event.type
	local session = event.target

	if e_type == session.ONCONNECT then
		self:dispatchEvent( Wamp.ONCONNECT )

	elseif e_type == session.ONJOIN then
		self:dispatchEvent( Wamp.ONJOIN )

	elseif e_type == session.ONCHALLENGE then
		assert( event.challenge )
		self:dispatchEvent( Wamp.ONCHALLENGE, { challenge=event.challenge } )

	end

end




return Wamp

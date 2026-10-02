--====================================================================--
-- dmc_corona/dmc_wamp.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-wamp
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

local VERSION = "1.1.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



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

local Utils = require 'lib.dmc_lua.lua_utils'



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


local Objects = require 'lib.dmc_lua.lua_objects'
local Patch = require 'lib.dmc_lua.lua_patch'
local WebSocket = require 'dmc_websockets'

local WError = require 'dmc_wamp.exception'
local WSerializerFactory = require 'dmc_wamp.serializer'
local WProtocol = require 'dmc_wamp.protocol'
local WTypes = require 'dmc_wamp.types'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass
Patch.addPatch( 'print-output' )

local assert = assert
local type = type

-- local control of development functionality
local LOCAL_DEBUG = dmc_wamp_data.debug_active~=nil and dmc_wamp_data.debug_active or false



--====================================================================--
--== Wamp Class
--====================================================================--


local Wamp = newClass( WebSocket, {name="WAMP Connector"} )

--== Class Constants ==--

Wamp.VERSION = VERSION

-- raise one in a registered procedure to send the caller an error URI
Wamp.ApplicationError = WError.ApplicationError

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

Wamp.ONREGISTERED = 'wamp_on_registered_event'
Wamp.ONUNREGISTERED = 'wamp_on_unregistered_event'

Wamp.ONRESULT = 'wamp_on_result_event'
Wamp.ONPROGRESS = 'wamp_on_progress_event'


--======================================================--
-- Start: Setup DMC Objects

function Wamp:__init__( params )
	-- print( "Wamp:__init__" )
	params = params or {}
	self:superCall( '__init__', params )
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
	self._disconnect_sent = false -- ONDISCONNECT sent for this connection

	self._serializer = nil -- a serializer object

end


function Wamp:__initComplete__()
	-- print( "Wamp:__initComplete__" )
	self:superCall( '__initComplete__' )

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
-- true while the realm is joined
--
function Wamp.__getters:is_connected()
	-- print( "Wamp.__getters:is_connected" )
	return ( self._session ~= nil and self._session._session_id ~= nil )
end


-- raises an error unless the realm is joined
--
function Wamp:_checkJoined( method )
	if not self.is_connected then
		error( "Wamp:" .. method .. " :: the realm isn't joined, wait for ONJOIN", 3 )
	end
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
	self:_checkJoined( 'call' )

	local success_f, progress_f, error_f

	success_f = function( res )
		-- a result with no arguments comes as nil
		res = res or WTypes.CallResult:new{}
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
-- callback - optional, gets ONREGISTERED: accepted (event.registration)
-- or refused (event.is_error, event.error)
--
function Wamp:register( handler, params )
	-- print( "Wamp:register", handler )
	params = params or {}
	assert( type(handler)=='function', "Wamp:register :: incorrect type for handler" )
	assert( type(params.procedure)=='string', "Wamp:register :: requires parameter 'procedure'" )
	--==--
	self:_checkJoined( 'register' )

	if params.pkeys or params.disclose_caller then
		params.options = WTypes.RegisterOptions:new( params )
	end

	local callback = params.callback
	local def = self._session:register( handler, params )

	def:addCallbacks(
		function( reg )
			if callback then
				callback{ is_error=false, name=Wamp.EVENT, type=Wamp.ONREGISTERED, registration=reg }
			end
		end,
		function( err )
			if callback then
				callback{ is_error=true, name=Wamp.EVENT, type=Wamp.ONREGISTERED, error=err }
			else
				print( "Wamp:register :: '" .. params.procedure .. "' refused: " .. tostring( err and err.error or err ) )
			end
		end
	)

	return def
end

-- unregister()
-- @param handler callback/object to handle Calls (same item as register())
-- @param params table of various parameters
--
-- callback - optional, gets ONUNREGISTERED (with event.is_error on failure)
--
function Wamp:unregister( handler, params )
	-- print( "Wamp:unregister", handler )
	params = params or {}
	assert( type(handler)=='function', "Wamp:unregister :: incorrect type for handler" )
	--==--
	self:_checkJoined( 'unregister' )

	local callback = params.callback

	try{
		function()
			local def = self._session:unregister( handler, params )
			def:addCallbacks(
				function()
					if callback then
						callback{ is_error=false, name=Wamp.EVENT, type=Wamp.ONUNREGISTERED }
					end
				end,
				function( err )
					if callback then
						callback{ is_error=true, name=Wamp.EVENT, type=Wamp.ONUNREGISTERED, error=err }
					end
				end
			)
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

	self:_checkJoined( 'publish' )

	local success_f, error_f
	local handler = params.callback

	-- with a callback, ask the router to acknowledge the publication
	if handler then params.options.acknowledge = true end

	success_f = function( pub )
		local evt = {
			is_error=false,
			name=Wamp.EVENT,
			type=Wamp.ONPUBLISHED,
			publication=pub
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
			if def then def:addCallbacks( success_f, error_f ) end
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

	self:_checkJoined( 'subscribe' )

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
	-- @TODO: check session, try
	local session = self._session
	if not session then
		pnotice( "Wamp:leave no active session" )
	else
		session:leave{
			reason=reason,
			message=message
		}
	end
end

-- closes the connection without leaving the realm first
--
function Wamp:close()
	-- print( "Wamp:close" )
	self:_wamp_close()
	self:superCall( 'close' )
end



--====================================================================--
--== Private Methods


-- ends the session (if any) and sends ONDISCONNECT, once per connection
-- params - from dmc-websockets' close or error: code, reason
--
function Wamp:_wamp_close( params )
	-- print( "Wamp:_wamp_close" )
	params = params or {}
	local session = self._session
	local details

	if session then
		session:onClose( params.reason )
		details = session._close_details
		self._session = nil
	end

	if self._disconnect_sent then return end
	self._disconnect_sent = true

	local evt = { code=params.code }
	if details then
		-- the session ended: leave(), the router's GOODBYE or ABORT,
		-- or the connection was lost while joined
		evt.reason, evt.message = details.reason, details.message
	else
		-- never joined: the router couldn't be reached, or closed the
		-- connection first
		evt.reason = 'wamp.close.transport_lost'
		evt.message = params.reason
	end
	self:dispatchEvent( Wamp.ONDISCONNECT, evt, {merge=true} )

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
	self._disconnect_sent = false

	self:dispatchEvent( Wamp.ONCONNECT )

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

	-- the session ended (eg, close()); frames already received are dropped
	if not self._session then return end

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

-- coming from websockets: the connection failed or was failed
-- ONERROR, then the session ends (ONDISCONNECT)
function Wamp:_onError( params )
	-- print( "Wamp:_onError" )
	self:superCall( '_onError', params )
	self:_wamp_close( params )
end



--====================================================================--
--== Event Handlers


function Wamp:_wampSessionEvent_handler( event )
	-- print( "Wamp:_wampSessionEvent_handler: ", event.type )
	local e_type = event.type
	local session = event.target

	if e_type == session.ONJOIN then
		self:dispatchEvent( Wamp.ONJOIN, { details=event.details }, {merge=true} )

	elseif e_type == session.ONCHALLENGE then
		assert( event.challenge )
		self:dispatchEvent( Wamp.ONCHALLENGE, { challenge=event.challenge }, {merge=true} )

	end

end




return Wamp

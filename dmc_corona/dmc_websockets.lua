--====================================================================--
-- dmc_corona/dmc_websockets.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-websockets
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
--== DMC Corona Library : DMC Websockets
--====================================================================--


--[[

WebSocket support adapted from:
* Lumen (http://github.com/xopxe/Lumen)
* lua-websocket (http://lipp.github.io/lua-websockets/)
* lua-resty-websocket (https://github.com/openresty/lua-resty-websocket)

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.6.0"



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
--== DMC WebSockets
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_websockets = dmc_lib_data.dmc_websockets or {}

local DMC_WEBSOCKETS_DEFAULTS = {
	debug_active=false,
}

local dmc_websockets_data = Utils.extend( dmc_lib_data.dmc_websockets, DMC_WEBSOCKETS_DEFAULTS )



--====================================================================--
--== Imports


local LuaStatesMixin = require 'lib.dmc_lua.lua_states_mix'
local Objects = require 'lib.dmc_lua.lua_objects'
local Patch = require 'lib.dmc_lua.lua_patch'

-- websocket modules
local ws_frame = require 'dmc_websockets.frame'
local ws_utf8 = require 'dmc_websockets.utf8'

-- what makes the connection: a transport. Each has the same members
-- and works in whole messages, see dmc_websockets/native.lua
--
-- an HTML5 build has no sockets: there the browser's WebSocket makes
-- the connection, see dmc_websockets/html5.lua
local IS_HTML5 = system.getInfo ~= nil and system.getInfo( 'platform' ) == 'html5'

local Transport = require( IS_HTML5 and 'dmc_websockets.html5' or 'dmc_websockets.native' )
local urllib = Transport.url



--====================================================================--
--== Setup, Constants


Patch.addAllPatches()

local StatesMix = LuaStatesMixin.StatesMix

local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local assert = assert
local sgettimer = system.getTimer
local tdelay = timer.performWithDelay
local tcancel = timer.cancel
local tinsert = table.insert
local tconcat = table.concat
local tremove = table.remove
local type = type

--== dmc_websocket Error Constants

local ERROR_CODES = {
	NETWORK_ERROR = { code=3000, reason="Network Error" },
	REQUEST_ERROR = { code=3001, reason="Request Error" },
	INVALID_HANDSHAKE = { code=3002, reason="Received invalid websocket handshake" },
	TIMEOUT = { code=3003, reason="No pong received in time" },
	INTERNAL = { code=9999, reason="Internal Error" },
}


-- a transport's 'error' event, by its kind
local TRANSPORT_ERRORS = {
	network = ERROR_CODES.NETWORK_ERROR,
	request = ERROR_CODES.REQUEST_ERROR,
	handshake = ERROR_CODES.INVALID_HANDSHAKE,
	internal = ERROR_CODES.INTERNAL,
}


local LOCAL_DEBUG = false



--====================================================================--
--== WebSocket Class
--====================================================================--


local WebSocket = newClass( { ObjectBase, StatesMix }, {name="DMC WebSocket"} )

-- version for the the group of WebSocket files
WebSocket.VERSION = VERSION
WebSocket.USER_AGENT = 'dmc_websockets/'..WebSocket.VERSION

--== Message Type Constants

WebSocket.TEXT = 'text'
WebSocket.BINARY = 'binary'

--== Throttle Constants

WebSocket.OFF = Transport.OFF
WebSocket.LOW = Transport.LOW
WebSocket.MEDIUM = Transport.MEDIUM
WebSocket.HIGH = Transport.HIGH

--== Connection-Status Constants

WebSocket.NOT_ESTABLISHED = 0
WebSocket.ESTABLISHED = 1
WebSocket.CLOSING_HANDSHAKE = 2
WebSocket.CLOSED = 3

--== State Constants

WebSocket.STATE_CREATE = "state_create"
WebSocket.STATE_INIT = "state_init"
WebSocket.STATE_CONNECTED = "state_connected"
WebSocket.STATE_CLOSING = "state_closing_connection"
WebSocket.STATE_CLOSED = "state_closed"

--== Event Constants

WebSocket.EVENT = 'websocket_event'

WebSocket.ONOPEN = 'onopen'
WebSocket.ONMESSAGE = 'onmessage'
WebSocket.ONERROR = 'onerror'
WebSocket.ONPONG = 'onpong'
WebSocket.ONCLOSE = 'onclose'


--======================================================--
-- Start: Setup DMC Objects

function WebSocket:__init__( params )
	-- print( "WebSocket:__init__" )
	params = params or {}
	if params.auto_connect==nil then params.auto_connect=true end
	if params.auto_reconnect==nil then params.auto_reconnect=false end

	self:superCall( ObjectBase, '__init__', params )
	self:superCall( StatesMix, '__init__', params )
	--==--

	--== Sanity Check ==--

	if self.is_class then return end

	assert( params.uri, "WebSocket: requires parameter 'uri'" )

	-- options this platform's transport can't honor
	Transport.checkParams( params )

	--== Create Properties ==--

	self._uri = params.uri
	self._port = params.port
	self._query = params.query
	self._origin = params.origin
	self._protocols = params.protocols

	-- keep-alive: milliseconds between pings (nil, off) and how long
	-- to wait for each pong before failing the connection
	self._keepalive = params.keepalive
	self._keepalive_timeout = params.keepalive_timeout or 10000
	self._keepalive_timer = nil
	self._ping_timer = nil
	self._ping_data = nil -- payload of the ping waiting for its pong
	self._ping_time = nil
	self._latency = nil

	self._auto_connect = params.auto_connect
	self._auto_reconnect = params.auto_reconnect

	self._msg_queue = {}
	self._msg_queue_handler = nil
	self._msg_queue_active = false

	self._transport_event_handler = nil -- ref to
	self._socket_throttle = params.throttle

	self._close_timer = nil

	--== Object References ==--

	self._conn = nil -- the transport's connection
	self._ssl_params = params.ssl_params

	-- set first state
	self:setState( WebSocket.STATE_CREATE )

end


function WebSocket:__initComplete__()
	-- print( "WebSocket:__initComplete__" )
	self:superCall( ObjectBase, '__initComplete__' )
	--==--

	self._transport_event_handler = self:createCallback( self._transportEvent_handler )
	self._msg_queue_handler = self:createCallback( self._processMessageQueue )

	if self._auto_connect == true then
		self:connect()
	end
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


-- connect()
--
function WebSocket:connect()
	-- print( 'WebSocket:connect' )
	self:gotoState( WebSocket.STATE_INIT )
end

-- .throttle
--
function WebSocket.__setters:throttle( value )
	-- print( 'WebSocket.__setters:throttle', value )
	Transport.setThrottle( value )
end

-- .readyState
--
function WebSocket.__getters:readyState()
	return self._ready_state
end

-- .latency
-- round trip of the last keep-alive ping, milliseconds (nil until measured)
--
function WebSocket.__getters:latency()
	return self._latency
end

-- send()
--
function WebSocket:send( data, params )
	-- print( "WebSocket:send", #data )
	assert( type(data)=='string', "expected string for send()")
	params = params or {}
	params.type = params.type or WebSocket.TEXT
	if params.type ~= WebSocket.BINARY then
		-- RFC 6455 5.6: a server fails the connection on anything else
		assert( ws_utf8.isValid( data ),
			"WebSocket: text must be valid UTF-8, send other data as BINARY" )
	end
	--==--

	if params.type == WebSocket.BINARY then
		self:_sendBinary( data )
	else
		self:_sendText( data )
	end

end

-- ping()
-- the server answers with a pong, dispatched as ONPONG
--
function WebSocket:ping( data )
	assert( Transport.can_ping,
		"WebSocket: ping() isn't available in HTML5 builds, browsers don't let scripts send pings" )
	data = data or ''
	assert( type(data)=='string', "expected string for ping()" )
	assert( #data <= 125, "ping data is limited to 125 bytes" )
	--==--
	if self:getState() ~= WebSocket.STATE_CONNECTED then return end
	self:_sendPing( data )
end

-- close()
--
function WebSocket:close()
	-- print( "WebSocket:close" )
	local evt = Utils.extend( ws_frame.close.OK, {} )
	self:_close( evt )
end



--====================================================================--
--== Private Methods


--== the following "_on"-methods dispatch event to app client level

function WebSocket:_onOpen()
	-- print( "WebSocket:_onOpen" )
	self:dispatchEvent( self.ONOPEN )
end

--[[
	msg={
		data='',
		ftype=''
	}
--]]
function WebSocket:_onMessage( msg )
	-- print( "WebSocket:_onMessage", msg )
	local evt = {
		message=msg
	}
	self:dispatchEvent( WebSocket.ONMESSAGE, evt, {merge=true} )
end

function WebSocket:_onPong( data, latency )
	-- print( "WebSocket:_onPong", data )
	local evt = {
		data=data,
		latency=latency
	}
	self:dispatchEvent( WebSocket.ONPONG, evt, {merge=true} )
end

function WebSocket:_onClose( params )
	-- print( "WebSocket:_onClose", params )
	params = params or {}
	--==--
	local evt = {
		code=params.code,
		reason=params.reason
	}
	self:dispatchEvent( self.ONCLOSE, evt, {merge=true} )
end

function WebSocket:_onError( params )
	-- print( "WebSocket:_onError", params )

	local evt = {
		isError=true,
		code=params.code,
		reason=params.reason,
		emsg=params.emsg
	}
	self:dispatchEvent( self.ONERROR, evt, {merge=true} )
end


-- the query option: a string as is, or a table of names and values
--
function WebSocket:_encodeQuery( query )
	if type( query ) == 'string' then
		return query ~= '' and query or nil
	elseif type( query ) ~= 'table' then
		return nil
	end
	local parts = {}
	for k, v in pairs( query ) do
		tinsert( parts, urllib.escape( tostring( k ) ) .. '=' .. urllib.escape( tostring( v ) ) )
	end
	if #parts == 0 then return nil end
	table.sort( parts ) -- same order every time
	return tconcat( parts, '&' )
end


-- fail our connection with an error
--
function WebSocket:_bailout( params )
	-- print( "Failing connection", params.code, params.reason )
	params = params or {}
	--==--
	params.isError = true
	params.reconnect = false
	self:gotoState( WebSocket.STATE_CLOSED, params )
end


-- request to close the connection
--
function WebSocket:_close( params )
	-- print( "WebSocket:_close" )
	params = params or {}
	local default_close = ws_frame.close.GOING_AWAY
	params.code = params.code or default_close.code
	params.reason = params.reason or default_close.reason
	--==--
	params.reconnect = params.reconnect == nil and true or params.reconnect

	local state = self:getState()

	if state == WebSocket.STATE_CLOSED then
		-- pass

	elseif state == WebSocket.STATE_CLOSING then
		self:gotoState( WebSocket.STATE_CLOSED, params )

	elseif state == WebSocket.STATE_INIT then
		-- still connecting: give up on it
		self:gotoState( WebSocket.STATE_CLOSED, params )

	else
		self:gotoState( WebSocket.STATE_CLOSING, params )

	end

end


function WebSocket:_sendBinary( data )
	self:_sendMessage{ kind=WebSocket.BINARY, data=data }
end
function WebSocket:_sendClose( code, reason )
	-- print( "WebSocket:_sendClose", code, reason )
	self:_sendMessage{ kind='close', code=code, reason=reason }
end
function WebSocket:_sendPing( data )
	self:_sendMessage{ kind='ping', data=data }
end
function WebSocket:_sendPong( data )
	self:_sendMessage{ kind='pong', data=data }
end
function WebSocket:_sendText( data )
	self:_sendMessage{ kind=WebSocket.TEXT, data=data }
end



--== Keep-alive: ping, wait for its pong, wait the interval, ping again

function WebSocket:_startKeepalive()
	-- print( "WebSocket:_startKeepalive" )
	if type( self._keepalive ) ~= 'number' or self._keepalive <= 0 then return end
	self:_stopKeepalive()
	local f = function()
		self._keepalive_timer = nil
		self:_sendKeepalivePing()
	end
	self._keepalive_timer = tdelay( self._keepalive, f )
end

function WebSocket:_stopKeepalive()
	-- print( "WebSocket:_stopKeepalive" )
	if self._keepalive_timer then
		tcancel( self._keepalive_timer )
		self._keepalive_timer = nil
	end
	if self._ping_timer then
		tcancel( self._ping_timer )
		self._ping_timer = nil
	end
	self._ping_data = nil
end

function WebSocket:_sendKeepalivePing()
	-- print( "WebSocket:_sendKeepalivePing" )
	if self:getState() ~= WebSocket.STATE_CONNECTED then return end

	self._ping_count = ( self._ping_count or 0 ) + 1
	self._ping_data = 'keepalive ' .. self._ping_count
	self._ping_time = sgettimer()
	self:_sendPing( self._ping_data )

	local f = function()
		self._ping_timer = nil
		self._ping_data = nil
		self:_bailout{
			code=ERROR_CODES.TIMEOUT.code,
			reason=ERROR_CODES.TIMEOUT.reason,
		}
	end
	self._ping_timer = tdelay( self._keepalive_timeout, f )
end

function WebSocket:_pongReceived( data )
	-- print( "WebSocket:_pongReceived", data )
	local latency
	if self._ping_data and data == self._ping_data then
		latency = sgettimer() - self._ping_time
		self._latency = latency
		self:_startKeepalive() -- also clears the pong timeout
	end
	self:_onPong( data, latency )
end


function WebSocket:_sendMessage( data )
	-- print( "WebSocket:_sendMessage" )
	--==--
	if self:getState() == WebSocket.STATE_CLOSED then
		-- pass
	else
		self:_addMessageToQueue( data )
	end
end


function WebSocket:_addMessageToQueue( message )
	-- print( "WebSocket:_addMessageToQueue" )
	--==--
	tinsert( self._msg_queue, message )
	self:_processMessageQueue()

	-- if we still have info left, then set listener
	if not self._msg_queue_active and #self._msg_queue > 0 then
		Runtime:addEventListener( 'enterFrame', self._msg_queue_handler )
		self._msg_queue_active = true
	end
end
function WebSocket:_removeMessageFromQueue( message )
	-- print( "WebSocket:_removeMessageFromQueue" )
	--==--
	tremove( self._msg_queue, 1 )

	if #self._msg_queue == 0 and self._msg_queue_active then
		Runtime:removeEventListener( 'enterFrame', self._msg_queue_handler )
		self._msg_queue_active = false
	end
end

function WebSocket:_processMessageQueue()
	-- print( "WebSocket:_processMessageQueue", #self._msg_queue )

	if #self._msg_queue == 0 then return end

	-- a transport takes messages only once the connection is open
	local state = self:getState()
	if state == WebSocket.STATE_CLOSED then
		while #self._msg_queue > 0 do
			self:_removeMessageFromQueue( self._msg_queue[1] )
		end
		return
	elseif state ~= WebSocket.STATE_CONNECTED and state ~= WebSocket.STATE_CLOSING then
		return
	end

	local conn = self._conn
	local start = sgettimer()

	repeat
		local msg = self._msg_queue[1]
		self:_removeMessageFromQueue( msg )
		if msg.kind == 'close' then
			conn:sendClose( msg.code, msg.reason )
		else
			conn:send( msg.kind, msg.data )
		end
		local diff = sgettimer() - start
	until #self._msg_queue == 0 or diff > 0
end


--======================================================--
-- START: STATE MACHINE

function WebSocket:state_create( next_state, params )
	-- print( "WebSocket:state_create >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_INIT then
		self:do_state_init( params )

	else
		print( "WARNING :: WebSocket:state_create " .. tostring( next_state ) )
	end

end


--== Initialize

function WebSocket:do_state_init( params )
	-- print( "WebSocket:do_state_init" )
	params = params or {}
	--==--
	self._ready_state = self.NOT_ESTABLISHED
	self:setState( WebSocket.STATE_INIT )

	local uri = self._uri
	local url_parts = urllib.parse( uri )
	local host = url_parts.host
	local port = url_parts.port
	local path = url_parts.path
	local query = url_parts.query

	local port = self._port or port

	if port == nil or port == 0 then
		port = url_parts.scheme == 'wss' and 443 or 80
	end

	if not path or path == "" then
		path = "/"
	end
	local opt_query = self:_encodeQuery( self._query )
	if query and query ~= '' and opt_query then
		query = query .. '&' .. opt_query
	elseif opt_query then
		query = opt_query
	end
	if query and query ~= '' then
		path = path .. '?' .. query
	end

	self._host = host
	self._path = path
	self._port = port

	if self._conn then self._conn:close() end

	-- shared by all connections: change it only when asked to
	if self._socket_throttle ~= nil then
		Transport.setThrottle( self._socket_throttle )
	end

	self._conn = Transport.connect{
		scheme=url_parts.scheme,
		host=host,
		port=port,
		path=path,
		protocols=self._protocols,
		origin=self._origin,
		user_agent=WebSocket.USER_AGENT,
		ssl_params=self._ssl_params,
		onEvent=self._transport_event_handler
	}

	-- failed while connecting
	if self:getState() == WebSocket.STATE_CLOSED then self._conn:close() end

end

function WebSocket:state_init( next_state, params )
	-- print( "WebSocket:state_init >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_CLOSED then
		self:do_state_closed( params )

	elseif next_state == WebSocket.STATE_CONNECTED then
		-- the transport made the connection and the handshake
		self:do_state_connected( params )

	else
		print( "WARNING :: WebSocket:state_init " .. tostring( next_state ) )
	end

end


--== Connected

function WebSocket:do_state_connected( params )
	-- print( "WebSocket:do_state_connected" )
	params = params or {}
	--==--

	self._ready_state = WebSocket.ESTABLISHED
	self:setState( WebSocket.STATE_CONNECTED )

	if LOCAL_DEBUG then
		print( "dmc_websockets:: Connected to server" )
	end

	self:_onOpen()
	self:_startKeepalive()

	-- send any waiting messages
	self:_processMessageQueue()

end
function WebSocket:state_connected( next_state, params )
	-- print( "WebSocket:state_connected >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_CLOSING then
		self:do_state_closing_connection( params )

	elseif next_state == WebSocket.STATE_CLOSED then
		self:do_state_closed( params )

	else
		print( "WARNING :: WebSocket:state_connected %s" % tostring( next_state ) )
	end

end


--== Closing

function WebSocket:do_state_closing_connection( params )
	-- print( "WebSocket:do_state_closing_connection", params )
	params = params or {}
	params.from_server = params.from_server ~= nil and params.from_server or false
	--==--

	self._ready_state = WebSocket.CLOSING_HANDSHAKE
	self:setState( WebSocket.STATE_CLOSING )
	self:_stopKeepalive()

	-- send close code to server
	if params.code then
		self:_sendClose( params.code, params.reason )
	end

	-- if this close is from server, then close else wait
	if params.from_server then
		self:gotoState( WebSocket.STATE_CLOSED, params )

	else
		-- set timer to politely wait for server close response
		local f = function()
			print( "ERROR: Close response not received" )
			self._close_timer = nil
			self:gotoState( WebSocket.STATE_CLOSED, { code=params.code, reason=params.reason } )
		end
		self._close_timer = tdelay( 4000, f )
	end

end
function WebSocket:state_closing_connection( next_state, params )
	-- print( "WebSocket:state_closing_connection >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_CLOSED then
		self:do_state_closed( params )

	else
		print( "WARNING :: WebSocket:state_closing_connection %s" % tostring( next_state ) )
	end

end


--== Closed

function WebSocket:do_state_closed( params )
	-- print( "WebSocket:do_state_closed" )
	params = params or {}
	--==--

	self._ready_state = WebSocket.CLOSED
	self:setState( WebSocket.STATE_CLOSED )
	self:_stopKeepalive()

	if self._close_timer then
		-- print( "Close response received" )
		tcancel( self._close_timer )
		self._close_timer = nil
	end

	if self._conn then self._conn:close() end

	if LOCAL_DEBUG then
		print( "dmc_websockets:: Server connection closed" )
	end

	if params.isError then
		self:_onError( params )
	else
		self:_onClose( params )
	end

end
function WebSocket:state_closed( next_state, params )
	-- print( "WebSocket:state_closed >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_CLOSED then
		self:do_state_closed( params )

	else
		print( "WARNING :: WebSocket:state_closed %s" % tostring( next_state ) )
	end

end

-- END: STATE MACHINE
--======================================================--



--====================================================================--
--== Event Handlers


-- handle events from the transport's connection
--
function WebSocket:_transportEvent_handler( event )
	-- print( "WebSocket:_transportEvent_handler", event.type )
	local etype = event.type
	local state = self:getState()

	if etype == 'open' then
		if state == WebSocket.STATE_INIT then
			self:gotoState( WebSocket.STATE_CONNECTED )
		end

	elseif etype == 'message' then
		if state == WebSocket.STATE_CONNECTED or state == WebSocket.STATE_CLOSING then
			self:_onMessage{ data=event.data, type=event.ftype }
		end

	elseif etype == 'ping' then
		if state == WebSocket.STATE_CONNECTED then
			self:_sendPong( event.data )
		end

	elseif etype == 'pong' then
		self:_pongReceived( event.data )

	elseif etype == 'close' then
		-- the server's close
		self:_close{
			code=event.code,
			reason=event.reason,
			from_server=true
		}

	elseif etype == 'drop' then
		-- the connection ended without a closing handshake
		if state ~= WebSocket.STATE_CLOSED then
			self:gotoState( WebSocket.STATE_CLOSED )
		end

	elseif etype == 'protocol_error' then
		-- what the server sent breaks the protocol: close with the code
		self:_close{
			code=event.code,
			reason=event.reason
		}

	elseif etype == 'error' then
		-- unreachable server, refused handshake, failed TLS, a dropped
		-- connection, or an error in app code run from an event
		local err = TRANSPORT_ERRORS[ event.kind ] or ERROR_CODES.NETWORK_ERROR
		self:_bailout{
			code=err.code,
			reason=err.reason,
			emsg=event.emsg
		}

	end
end




return WebSocket

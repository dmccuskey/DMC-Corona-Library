--====================================================================--
-- dmc_websockets.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_websockets.lua
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
-- DMC Corona Library : DMC Websockets
--====================================================================--

--[[

WebSocket support adapted from:
* Lumen (http://github.com/xopxe/Lumen)
* lua-websocket (http://lipp.github.io/lua-websockets/)
* lua-resty-websocket (https://github.com/openresty/lua-resty-websocket)

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.0"



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
-- DMC WebSockets
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_websockets = dmc_lib_data.dmc_websockets or {}

local DMC_WEBSOCKETS_DEFAULTS = {
	debug_active=false,
}

local dmc_websockets_data = Utils.extend( dmc_lib_data.dmc_websockets, DMC_WEBSOCKETS_DEFAULTS )


--====================================================================--
-- Imports

local mime = require 'mime'
local Objects = require 'dmc_objects'
local Sockets = require 'dmc_sockets'
local States = require 'dmc_states'
local urllib = require 'socket.url'
local Utils = require 'dmc_utils'

local patch = require 'dmc_patch'

-- websockets helpers

local wsframe = require 'dmc_websockets.frame'
local wshandshake = require 'dmc_websockets.handshake'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase

-- local control of development functionality
local LOCAL_DEBUG = false

local encode_base64 = mime.b64
local rand = math.random
local char = string.char
local concat = table.concat



--====================================================================--
-- WebSocket Class
--====================================================================--

local WebSocket = inheritsFrom( CoronaBase )
WebSocket.NAME = "WebSocket Class"

States.mixin( WebSocket )


--== Message Type Constants

WebSocket.TEXT = 'text'
WebSocket.BINARY = 'binary'


--== Throttle Constants

WebSocket.OFF = Sockets.OFF
WebSocket.LOW = Sockets.LOW
WebSocket.MEDIUM = Sockets.MEDIUM
WebSocket.HIGH = Sockets.HIGH


--== Connection-Status Constants

WebSocket.NOT_ESTABLISHED = 0
WebSocket.ESTABLISHED = 1
WebSocket.CLOSING_HANDSHAKE = 2
WebSocket.CLOSED = 3


--== Protocol Close Constants

WebSocket.CLOSE_STATUS_CODE_NORMAL = 1000
WebSocket.CLOSE_STATUS_CODE_GOING_AWAY = 1001
WebSocket.CLOSE_STATUS_CODE_PROTOCOL_ERROR = 1002
WebSocket.CLOSE_STATUS_CODE_UNSUPPORTED_DATA = 1003


--== State Constants

WebSocket.STATE_CREATE = "state_create"
WebSocket.STATE_INIT = "state_init"
WebSocket.STATE_NOT_CONNECTED = "state_not_connected"
WebSocket.STATE_HTTP_NEGOTIATION = "state_http_negotiation"
WebSocket.STATE_CONNECTED = "state_connected"
WebSocket.STATE_CLOSING = "state_closing_connection"
WebSocket.STATE_CLOSED = "state_closed"


--== Event Constants

WebSocket.EVENT = 'websocket_event'

WebSocket.ONOPEN = 'onopen'
WebSocket.ONMESSAGE = 'onmessage'
WebSocket.ONERROR = 'onerror'
WebSocket.ONCLOSE = 'onclose'


--====================================================================--
--== Start: Setup DMC Objects

function WebSocket:_init( params )
	-- print( "WebSocket:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	if not self.is_intermediate and ( not params.uri ) then
		error( "WebSocket: requires parameter 'uri'" )
	end

	--== Create Properties ==--

	self._uri = params.uri
	self._port = params.port
	self._protocols = params.protocols

	self._msg_queue = {}
	self._current_frame = nil -- used to build data from frames

	-- self._max_payload_len = params.max_payload_len
	-- self._send_unmasked = params.send_unmasked or false
	-- self._rd_frame_co = nil -- ref to read-frame coroutine

	self._socket_handler = nil -- ref to
	self._socket_throttle = params.throttle

	self._close_timer = nil


	--== Object References ==--

	self._socket = nil


	-- set first state
	self:setState( WebSocket.STATE_CREATE )

end


function WebSocket:_initComplete()
	-- print( "WebSocket:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	self:gotoState( WebSocket.STATE_INIT )

end

--== END: Setup DMC Objects
--====================================================================--



--====================================================================--
--== Public Methods

function WebSocket.__setters:throttle( value )
	-- print( 'WebSocket.__setters:throttle', value )
	Sockets.throttle = value
end


function WebSocket.__getters:readyState()
	return self._ready_state
end


function WebSocket:send( data, params )
	-- print( "WebSocket:send", #data )
	params = params or {}
	--==--

	local mtype = params.type or WebSocket.TEXT

	if mtype == WebSocket.BINARY then
		self:_sendBinary( data )
	else
		self:_sendText( data )
	end

end


function WebSocket:close()
	-- print( "WebSocket:close" )
	local evt = Utils.extend( wsframe.close_code.OK, {} )
	self:_close( evt )
end


--====================================================================--
--== Private Methods

function WebSocket:_onOpen()
	-- print( "WebSocket:_onOpen" )
	self:_dispatchEvent( self.ONOPEN )
end

-- msg: data, ftype
function WebSocket:_onMessage( msg )
	-- print( "WebSocket:_onMessage", msg )
	self:_dispatchEvent( WebSocket.ONMESSAGE, { message=msg }, {merge=true} )
end

function WebSocket:_onClose()
	-- print( "WebSocket:_onClose" )
	self:_dispatchEvent( self.ONCLOSE )
end

function WebSocket:_onError( ecode, emsg )
	-- print( "WebSocket:_onError", ecode, emsg )
	self:_dispatchEvent( self.ONERROR, {is_error=true, error=ecode, emsg=emsg }, {merge=true} )
end


function WebSocket:_doHttpConnect()
	-- print( "WebSocket:_doHttpConnect" )

	local params, request, callback

	-- create request

	params = {
		host=self._host,
		port=self._port,
		path=self._path,
		protocols=self._protocols
	}
	request = wshandshake.createRequest( params )

	-- request callback

	callback = function( event )
		if event.error then
			self:_onError( -1, "failed to send the handshake request: " .. err )

			self:_close( { reconnect=false } )
		end
	end

	-- TODO: handle error condition
	if request then
		self._socket:send( request, callback )
	else
		self:_close( { reconnect=false } )
	end

end


function WebSocket:_handleHttpRespose()
	-- print( "WebSocket:_handleHttpRespose" )

	local callback = function( event )
		-- print( "WebSocket:_handleHttpRespose callback" )
		if not event.data then
			-- print( event.emsg )
			self:_close( { reconnect=false } )

		else
			local header_ok = wshandshake.checkResponse( { data=event.data })
			if header_ok then
				self:gotoState( WebSocket.STATE_CONNECTED )
			else
				self:_close( { reconnect=false } )
			end

		end
	end

	self._socket:receiveUntilNewline( callback )
end


function WebSocket:_receiveFrame()
	-- print( "WebSocket:_receiveFrame" )

	local state = self:getState()
	local sock = self._socket

	local onFrame, onError, params

	-- check current state

	if state ~= WebSocket.STATE_CONNECTED and state ~= WebSocket.STATE_CLOSING then
		self:_onError( -1, "WebSocket is not connected" )
	end

	-- setup frame callbacks

	onFrame = function( event )
		-- print("got frame", event.type, event.data )
		local ftype, data = event.type, event.data

		if not data and not str_find(err, ": timeout", 1, true) then
			self:_onError( -1, err )

		elseif ftype == 'continuation' then
			print( 'TODO: frame', data, ftype, err )
			-- TODO: need to rebuild frame data

		elseif ftype == 'text' or ftype == 'binary' then
			local msg = { data=data, type=ftype }
			self:_onMessage( msg )

		elseif ftype == 'close' then
			local code, reason = wsframe.decodeCloseFrameData( data )
			self:_close( { code=code, reason=reason } )

		elseif ftype == 'ping' then
			if self:getState() == WebSocket.STATE_CONNECTED then
				self:_sendPong( data )
			end

		elseif ftype == 'pong' then
			print( "received frame: '" .. ftype .. "'", data, err )

		end

		-- see if we have more frames to read
		wsframe.receiveFrame( params )

	end

	onError = function( event )
		print( "ERROR FRAME", event.emsg )
	end

	params = {
		socket=self._socket,
		onFrame = onFrame,
		onError = onError
	}
	wsframe.receiveFrame( params )

end


function WebSocket:_sendFrame( msg )
	-- print( "WebSocket:_sendFrame", msg.opcode )

	local opcode = msg.opcode or wsframe.type.text
	local data = msg.data
	local masked = true -- always when client to server

	local sock = self._socket

	local onFrameCallback = function( event )
		-- print("received built frame: size", #event.frame )
		if not event.frame then
			self:_onError( -1, event.emsg )
		else
			-- process frame
			local socketCallback = function( event )
			end
			self._socket:send( event.frame, socketCallback )
		end
	end

	local p = {
		data=data,
		opcode=opcode,
		masked=masked,
		onFrame=onFrameCallback,
		-- max_frame_size (optional)
	}
	wsframe.buildFrames( p )

end


function WebSocket:_bailout( params )
	print("Failing connection", params.code, params.reason )
	self:_close( params )
end



function WebSocket:_close( params )
	-- print( "WebSocket:_close" )
	params = params or {}
	params.code = params.code or 1001
	params.reason = params.reason or "Going Away"
	--==--
	params.reconnect = params.reconnect == nil and true or false

	local state = self:getState()

	if state == WebSocket.STATE_CLOSED then
		-- pass

	elseif state == WebSocket.STATE_CLOSING then
		self:gotoState( WebSocket.STATE_CLOSED )

	elseif state == WebSocket.STATE_NOT_CONNECTED or state == WebSocket.STATE_HTTP_NEGOTIATION then
		self:gotoState( WebSocket.STATE_CLOSED )

	else
		self:gotoState( WebSocket.STATE_CLOSING, params )

	end

end


function WebSocket:_sendBinary( data )
	local msg = { opcode=wsframe.type.binary, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendClose( code, reason )
	-- print( "WebSocket:_sendClose", code, reason )
	local data = wsframe.encodeCloseFrameData( code, reason )
	local msg = { opcode=wsframe.type.close, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendPing( data )
	local msg = { opcode=wsframe.type.ping, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendPong( data )
	local msg = { opcode=wsframe.type.pong, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendText( data )
	local msg = { opcode=wsframe.type.text, data=data }
	self:_sendMessage( msg )
end


function WebSocket:_sendMessage( msg )
	-- print( "WebSocket:_sendMessage" )
	params = params or {}
	--==--

	local state = self:getState()

	-- build frames
	-- queue frames
	-- send frames

	if false then
		self:_addMessageToQueue( msg )

	elseif state == WebSocket.STATE_CLOSED then
		-- pass

	else
		self:_sendFrame( msg )

	end

end


function WebSocket:_addMessageToQueue( msg )
	-- print( "WebSocket:_addMessageToQueue" )
	table.insert( self._msg_queue, msg )
end

function WebSocket:_processMessageQueue()
	-- print( "WebSocket:_processMessageQueue" )
	for _, msg in ipairs( self._msg_queue ) do
		self:_sendMessage( msg )
	end
	self._msg_queue = {}
end


--====================================================================--
--== START: STATE MACHINE

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
	local path = url_parts.path

	local port = self._port

	if not port then
		port = 80
	end

	if not path or path == "" then
		path = "/"
	end

	self._host = host
	self._path = path
	self._port = port

	if self._socket then self._socket:close() end

	self._socket = Sockets:create( Sockets.ATCP )
	Sockets.throttle = self._socket_throttle
	self._socket_handler = self:createCallback( self._socketEvent_handler )

	print( "dmc_websockets:: Connecting to '%s:%s'" % { self._host, self._port } )
	self._socket:connect( host, port, { onConnect=self._socket_handler, onData=self._socket_handler } )

end

function WebSocket:state_init( next_state, params )
	-- print( "WebSocket:state_init >>", next_state )
	params = params or {}
	--==--

	if next_state == self.CLOSED then
		self:do_state_closed( params )

	elseif next_state == WebSocket.STATE_NOT_CONNECTED then
		self:do_state_not_connected( params )

	else
		print( "WARNING :: WebSocket:state_init " .. tostring( next_state ) )
	end

end


--== Not Connected

function WebSocket:do_state_not_connected( params )
	-- print( "WebSocket:do_state_not_connected" )
	params = params or {}
	--==--

	self._ready_state = self.NOT_ESTABLISHED

	self:setState( WebSocket.STATE_NOT_CONNECTED )

	-- do after state set
	print("dmc_websockets:: Sending WebSocket request to server ")
	self:_doHttpConnect()

end

function WebSocket:state_not_connected( next_state, params )
	-- print( "WebSocket:state_not_connected >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_HTTP_NEGOTIATION then
		self:do_state_http_negotiation( params )

	elseif next_state == WebSocket.STATE_CLOSED then
		self:do_state_closed( params )

	else
		print( "WARNING :: WebSocket:state_not_connected " .. tostring( next_state ) )
	end

end


--== HTTP Negotiation

function WebSocket:do_state_http_negotiation( params )
	-- print( "WebSocket:do_state_http_negotiation" )
	params = params or {}
	--==--

	self:setState( WebSocket.STATE_HTTP_NEGOTIATION )

	-- do this after setting state
	print("dmc_websockets:: Reading WebSocket response from server ")
	self:_handleHttpRespose()

end

function WebSocket:state_http_negotiation( next_state, params )
	-- print( "WebSocket:state_http_negotiation >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_CONNECTED then
		self:do_state_connected( params )

	elseif next_state == WebSocket.STATE_CLOSED then
		self:do_state_closed( params )

	else
		print( "WARNING :: WebSocket:state_http_negotiation %s" % tostring( next_state ) )
	end

end


--== Connected

function WebSocket:do_state_connected( params )
	-- print( "WebSocket:do_state_connected" )
	params = params or {}
	--==--

	self._ready_state = self.ESTABLISHED
	self:setState( WebSocket.STATE_CONNECTED )

	print( "dmc_websockets:: Connected to server" )

	self:_processMessageQueue()

	self:_onOpen()

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
	-- print( "WebSocket:do_state_closing_connection" )
	params = params or {}
	--==--

	self._ready_state = self.CLOSING_HANDSHAKE
	self:setState( WebSocket.STATE_CLOSING )

	if params.code then
		self:_sendClose( params.code, params.reason )
	end

	-- set timer to politely wait for server close response
	local f = function()
		-- print( "Close response not received" )
		self._close_timer = nil
		self:gotoState( WebSocket.STATE_CLOSED )
	end
	self._close_timer = timer.performWithDelay( 4000, f )

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

	self._ready_state = self.CLOSED
	self:setState( WebSocket.STATE_CLOSED )

	if self._close_timer then
		-- print( "Close response received" )
		timer.cancel( self._close_timer )
		self._close_timer = nil
	end

	self._socket:close()

	print( "dmc_websockets:: Server connection closed" )

	self:_onClose()

end
function WebSocket:state_closed( next_state, params )
	-- print( "WebSocket:state_closed >>", next_state )
	params = params or {}
	--==--

	if next_state == self.CLOSED then
		self:do_state_closed( params )

	else
		print( "WARNING :: WebSocket:state_closed %s" % tostring( next_state ) )
	end

end

--== END: STATE MACHINE
--====================================================================--



--====================================================================--
--== Event Handlers

function WebSocket:_socketEvent_handler( event )
	-- print( "WebSocket:_socketEvent_handler", event.type )

	local state = self:getState()
	local sock = self._socket

	if event.type == sock.CONNECT then

		if event.status == sock.CONNECTED then
			self:gotoState( WebSocket.STATE_NOT_CONNECTED )
		else
			self:gotoState( WebSocket.STATE_CLOSED )
		end

	elseif event.type == sock.READ then

		if state == WebSocket.STATE_NOT_CONNECTED then
			self:gotoState( WebSocket.STATE_HTTP_NEGOTIATION )

		else
			self:_receiveFrame()

		end

	end

end




return WebSocket

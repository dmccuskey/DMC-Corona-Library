--====================================================================--
-- dmc_corona/dmc_websockets.lua
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
--== DMC Corona Library : DMC Websockets
--====================================================================--


--[[

WebSocket support adapted from:
* Lumen (http://github.com/xopxe/Lumen)
* lua-websocket (http://lipp.github.io/lua-websockets/)
* lua-resty-websocket (https://github.com/openresty/lua-resty-websocket)

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.3.1"



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


local mime = require 'mime'
local urllib = require 'socket.url'

local ByteArray = require 'lib.dmc_lua.lua_bytearray'
local ByteArrayError = require 'lib.dmc_lua.lua_bytearray.exceptions'
local LuaStatesMixin = require 'lib.dmc_lua.lua_states_mix'
local Objects = require 'lib.dmc_lua.lua_objects'
local Patch = require 'lib.dmc_lua.lua_patch'
local Sockets = require 'dmc_sockets'
local Utils = require 'lib.dmc_lua.lua_utils'

-- websocket modules
local ws_error = require 'dmc_websockets.exception'
local ws_frame = require 'dmc_websockets.frame'
local ws_handshake = require 'dmc_websockets.handshake'
local ws_message = require 'dmc_websockets.message'



--====================================================================--
--== Setup, Constants


Patch.addAllPatches()

local StatesMix = LuaStatesMixin.StatesMix

local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local assert = assert
local sgmatch = string.gmatch
local sgettimer = system.getTimer
local tdelay = timer.performWithDelay
local tcancel = timer.cancel
local tinsert = table.insert
local tconcat = table.concat
local tremove = table.remove
local type = type

local ProtocolError = ws_error.ProtocolError
local BufferError = ByteArrayError.BufferError


--== dmc_websocket Close Constants

local CLOSE_CODES = {
	INTERNAL = { code=9999, reason="Internal Error" },
}

--== dmc_websocket Error Constants

local ERROR_CODES = {
	NETWORK_ERROR = { code=3000, reason="Network Error" },
	REQUEST_ERROR = { code=3001, reason="Request Error" },
	INVALID_HANDSHAKE = { code=3002, reason="Received invalid websocket handshake" },
	INTERNAL = { code=9999, reason="Internal Error" },
}


local LOCAL_DEBUG = false



--====================================================================--
--== WebSocket Class
--====================================================================--


local WebSocket = newClass( { ObjectBase, StatesMix }, {name="DMC WebSocket"} )

-- version for the the group of WebSocket files
WebSocket.VERSION = '1.2.0'
WebSocket.USER_AGENT = 'dmc_websockets/'..WebSocket.VERSION

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


--======================================================--
-- Start: Setup DMC Objects

function WebSocket:__init__( params )
	-- print( "WebSocket:__init__" )
	params = params or {}
	self:superCall( ObjectBase, '__init__', params )
	self:superCall( StatesMix, '__init__', params )
	--==--

	--== Sanity Check ==--

	if self.is_instance then
		assert( params.uri, "WebSocket: requires parameter 'uri'" )
	end

	--== Create Properties ==--

	self._uri = params.uri
	self._port = params.port
	self._query = params.query
	self._protocols = params.protocols

	self._auto_connect = params.auto_connect == nil and true or params.auto_connect
	self._auto_reconnect = params.auto_reconnect or false

	self._msg_queue = {}
	self._msg_queue_handler = nil
	self._msg_queue_active = false

	-- used to build data from frames, table
	self._current_frame = nil

	-- self._max_payload_len = params.max_payload_len
	-- self._send_unmasked = params.send_unmasked or false
	-- self._rd_frame_co = nil -- ref to read-frame coroutine

	self._socket_data_handler = nil -- ref to
	self._socket_connect_handler = nil -- ref to
	self._socket_throttle = params.throttle


	self._close_timer = nil

	self._ws_req_key = '' -- key sent to server on handshek

	--== Object References ==--

	self._ba = nil -- our Byte Array, buffer
	self._socket = nil
	self._ssl_params = params.ssl_params


	-- set first state
	self:setState( WebSocket.STATE_CREATE )

end


function WebSocket:__initComplete__()
	-- print( "WebSocket:__initComplete__" )
	self:superCall( ObjectBase, '__initComplete__' )
	--==--

	self._socket_connect_handler = self:createCallback( self._socketConnectEvent_handler )
	self._socket_data_handler = self:createCallback( self._socketDataEvent_handler )

	self._msg_queue_handler = self:createCallback( self._processMessageQueue )
	self:_createNewFrame()

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
	Sockets.throttle = value
end

-- .readyState
--
function WebSocket.__getters:readyState()
	return self._ready_state
end

-- send()
--
function WebSocket:send( data, params )
	-- print( "WebSocket:send", #data )
	assert( type(data)=='string', "expected string for send()")
	params = params or {}
	params.type = params.type or WebSocket.TEXT
	--==--

	if params.type == WebSocket.BINARY then
		self:_sendBinary( data )
	else
		self:_sendText( data )
	end

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
		reason=params.reason
	}
	self:dispatchEvent( self.ONERROR, evt, {merge=true} )
end


function WebSocket:_doHttpConnect()
	-- print( "WebSocket:_doHttpConnect" )

	local request, key = ws_handshake.createRequest{
		host=self._host,
		port=self._port,
		path=self._path,
		protocols=self._protocols
	}

	self._ws_req_key = key

	if not request then
		self:_bailout{
			code=ERROR_CODES.REQUEST_ERROR.code,
			reason=ERROR_CODES.REQUEST_ERROR.reason,
		}
		return
	end

	local callback = function( event )
		-- print("socket connect callback")
		if event.isError then
			self:_bailout{
				code=ERROR_CODES.REQUEST_ERROR.code,
				reason=ERROR_CODES.REQUEST_ERROR.reason,
			}
		end
	end
	self._socket:send( request, callback )

end


-- @param str raw returned header from HTTP request
--
-- split up string into individual lines
--
function WebSocket:_processHeaderString( str )
	-- print( "WebSocket:_processHeaderString" )
	local results = {}
	for line in sgmatch( str, '([^\r\n]*)\r\n') do
		tinsert( results, line )
	end
	return results
end

-- read header response string and see if it's valid
--
function WebSocket:_handleHttpRespose()
	-- print( "WebSocket:_handleHttpRespose" )
	local ba = self._ba

	-- first check if we have entire header to read
	local _, e_pos = ba:search( '\r\n\r\n' )
	if e_pos == nil then return end

	ba.pos = 1
	local h_str = ba:readBuf( e_pos )

	-- process header
	if ws_handshake.checkResponse( self:_processHeaderString( h_str ), self._ws_req_key ) then
		self:gotoState( WebSocket.STATE_CONNECTED )

	else
		self:_bailout{
			code=ERROR_CODES.INVALID_HANDSHAKE.code,
			reason=ERROR_CODES.INVALID_HANDSHAKE.reason,
		}
	end

end


--== Methods to handle non-/fragmented frames

function WebSocket:_createNewFrame()
	self._current_frame = {
		data = {},
		type = ''
	}
end
function WebSocket:_insertFrameData( data, ftype )
	local frame = self._current_frame

	--== Check for errors in Continuation

	-- there is no type for this frame and none from previous
	if ftype == nil and #frame.data == 0 then
		return nil
	end
	-- we already have a type/data from previous frame
	if ftype ~= nil and #frame.data > 0 then
		return nil
	end

	if ftype then frame.type = ftype end
	tinsert( frame.data, data )

	return data
end
function WebSocket:_processCurrentFrame()
	local frame = self._current_frame
	frame.data = tconcat( frame.data, '' )

	self:_createNewFrame()
	return frame
end


function WebSocket:_receiveFrame()
	-- print( "WebSocket:_receiveFrame" )

	local ws_types = ws_frame.type
	local ws_close = ws_frame.close

	-- check current state
	local state = self:getState()
	if state ~= WebSocket.STATE_CONNECTED and state ~= WebSocket.STATE_CLOSING then
		-- in process of closing, cancel frame check
		return
	end

	--== processing callback function

	local function handleWSFrame( frame_info )
		-- print("got frame", frame_info.type, frame_info.fin )
		-- print("got data", frame_info.data ) -- when testing, this could be A LOT of data
		local fcode, ftype, fin, data = frame_info.opcode, frame_info.type, frame_info.fin, frame_info.data
		if LOCAL_DEBUG then
			print( "Received msg type:" % ftype )
		end

		if fcode == ws_types.continuation then
			if not self:_insertFrameData( data ) then
				self:_close{
					code=ws_close.PROTO_ERR.code,
					reason=ws_close.PROTO_ERR.reason,
				}
				return
			end
			if fin then
				local msg = self:_processCurrentFrame()
				self:_onMessage( msg )
			end

		elseif fcode == ws_types.text or fcode == ws_types.binary then
			if not self:_insertFrameData( data, ftype ) then
				self:_close{
					code=ws_close.PROTO_ERR.code,
					reason=ws_close.PROTO_ERR.reason,
				}
				return
			end
			if fin then
				local msg = self:_processCurrentFrame()
				self:_onMessage( msg )
			end

		elseif fcode == ws_types.close then
			local code, reason = ws_frame.decodeCloseFrameData( data )
			self:_close{
				code=code or ws_close.OK.code,
				reason=reason or ws_close.OK.reason,
				from_server=true
			}

		elseif fcode == ws_types.ping then
			if self:getState() == WebSocket.STATE_CONNECTED then
				self:_sendPong( data )
			end

		elseif fcode == ws_types.pong then
			-- pass

		end
	end

	--== processing loop

	-- TODO: hook this up to enterFrame so large
	-- amount of frames won't pause processing

	local err = nil
	repeat

		local position = self._ba.pos -- save in case of errors
		try{
			function()
				handleWSFrame( ws_frame.receiveFrame( self._ba ) )
			end,
			catch{
				function(e)
					err=e
					self._ba.pos = position
				end
			}
		}
	until err or self:getState() == WebSocket.STATE_CLOSED

	--== handle error

	if not err then
		-- pass, WebSocket.STATE_CLOSED

	elseif not err.isa then
		-- always print this out, most likely a regular Lua error
		print( "\n\ndmc_websockets :: Unknown Error", err )
		print( debug.traceback() )
		self:_bailout{
			code=CLOSE_CODES.INTERNAL.code,
			reason=CLOSE_CODES.INTERNAL.reason
		}

	elseif err:isa( BufferError ) then
		-- pass, not enough data to read another frame

	elseif err:isa( ws_error.ProtocolError ) then
		if LOCAL_DEBUG then
			print( "dmc_websockets :: Protocol Error:", err.message )
			print( "dmc_websockets :: Protocol Error:", err.traceback )
		end
		self:_close{
			code=err.code,
			reason=err.reason,
		}

	else
		if LOCAL_DEBUG then
			print( "dmc_websockets :: Unknown Error", err.code, err.reason, err.message )
		end
		self:_bailout{
			code=CLOSE_CODES.INTERNAL.code,
			reason=CLOSE_CODES.INTERNAL.reason
		}
	end

end

-- @param msg WebSocket Message object
--
function WebSocket:_sendFrame( msg )
	-- print( "WebSocket:_sendFrame", msg )

	local sock = self._socket
	local record, callback

	msg.masked = true -- always when client to server

	callback = function( event )
		-- print("socket connect callback")
		if event.isError then
			self:_bailout{
				code=ERROR_CODES.NETWORK_ERROR.code,
				reason=ERROR_CODES.NETWORK_ERROR.reason,
			}
		end
	end

	record = ws_frame.buildFrames{
		message=msg,
		-- max_frame_size = 16  -- TODO: add functionality to fragment a message
	}
	sock:send( record.frame, callback )

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

	elseif state == WebSocket.STATE_NOT_CONNECTED or state == WebSocket.STATE_HTTP_NEGOTIATION then
		self:gotoState( WebSocket.STATE_CLOSED, params )

	else
		self:gotoState( WebSocket.STATE_CLOSING, params )

	end

end


function WebSocket:_sendBinary( data )
	local msg = ws_message{ opcode=ws_frame.type.binary, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendClose( code, reason )
	-- print( "WebSocket:_sendClose", code, reason )
	local data = ws_frame.encodeCloseFrameData( code, reason )
	local msg = ws_message{ opcode=ws_frame.type.close, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendPing( data )
	local msg = ws_message{ opcode=ws_frame.type.ping, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendPong( data )
	local msg = ws_message{ opcode=ws_frame.type.pong, data=data }
	self:_sendMessage( msg )
end
function WebSocket:_sendText( data )
	local msg = ws_message{ opcode=ws_frame.type.text, data=data }
	self:_sendMessage( msg )
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
	assert( message:isa( ws_message ), "expected message object" )
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
	assert( message:isa( ws_message ), "expected message object" ) -- ADD
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
	local start = sgettimer()

	repeat
		local msg = self._msg_queue[1]
		self:_sendFrame( msg )
		if msg:getAvailable() == 0 then
			self:_removeMessageFromQueue( msg )
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
	local socket = self._socket

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
	if query then
		path = path .. '?' .. query
	end

	self._host = host
	self._path = path
	self._port = port

	if socket then socket:close() end

	Sockets.throttle = self._socket_throttle

	socket = Sockets:create( Sockets.ATCP, {ssl_params=self._ssl_params} )
	socket.secure = (url_parts.scheme == 'wss') -- true/false
	self._socket = socket

	if LOCAL_DEBUG then
		print( "dmc_websockets:: Connecting to '%s:%s'" % { self._host, self._port } )
	end

	socket:connect( host, port, { onConnect=self._socket_connect_handler, onData=self._socket_data_handler } )

end

function WebSocket:state_init( next_state, params )
	-- print( "WebSocket:state_init >>", next_state )
	params = params or {}
	--==--

	if next_state == WebSocket.STATE_CLOSED then
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

	self._ready_state = WebSocket.NOT_ESTABLISHED

	self:setState( WebSocket.STATE_NOT_CONNECTED )

	-- do after state set
	if LOCAL_DEBUG then
		print("dmc_websockets:: Sending WebSocket connect request to server ")
	end
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
	if LOCAL_DEBUG then
		print("dmc_websockets:: Reading WebSocket connect response from server ")
	end
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

	self._ready_state = WebSocket.ESTABLISHED
	self:setState( WebSocket.STATE_CONNECTED )

	if LOCAL_DEBUG then
		print( "dmc_websockets:: Connected to server" )
	end

	self:_onOpen()

	-- check if more data after reading header
	self:_receiveFrame()

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

	if self._close_timer then
		-- print( "Close response received" )
		tcancel( self._close_timer )
		self._close_timer = nil
	end

	self._socket:close()
	self._ba = nil

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


-- handle connection events from socket
--
function WebSocket:_socketConnectEvent_handler( event )
	-- print( "WebSocket:_socketConnectEvent_handler", event.type, event.status )

	local state = self:getState()
	local sock = self._socket

	if event.type == sock.CONNECT then

		if event.isError then
			self:gotoState( WebSocket.STATE_CLOSED )
		elseif event.status == sock.CONNECTED then
			self:gotoState( WebSocket.STATE_NOT_CONNECTED )
		else
			if state ~= WebSocket.STATE_CLOSED then
				self:gotoState( WebSocket.STATE_CLOSED )
			end
		end
	end

end

-- handle read/write events from socket
--
function WebSocket:_socketDataEvent_handler( event )
	-- print( "WebSocket:_socketDataEvent_handler", event.type, event.status )

	local state = self:getState()
	local sock = self._socket

	if event.type == sock.READ then

		local callback = function( s_event )
			local data = s_event.data

			local ba = ByteArray:new()
			if self._ba then
				ba:writeBytes( self._ba )
			end
			self._ba = ba

			ba:writeBuf( data ) -- copy in new data

			-- if LOCAL_DEBUG then
			-- 	print( 'Data', #data, ba:getAvailable(), ba.pos )
			-- 	Utils.hexDump( data )
			-- end

			if state == WebSocket.STATE_NOT_CONNECTED then
				self:gotoState( WebSocket.STATE_HTTP_NEGOTIATION )
			else
				self:_receiveFrame()
			end

		end

		sock:receive( '*a', callback )

	end

end




return WebSocket

--====================================================================--
-- dmc_corona/dmc_websockets/native.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-websockets
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014-2026 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : DMC WebSockets Native Transport
--====================================================================--


--[[

The transport for devices and the Simulator: a TCP socket (dmc_sockets),
the opening handshake and the frames, all done here in Lua.

It has the same members as the browser transport (dmc_websockets/html5.lua),
so the WebSocket class works with whole messages and never sees a socket,
a handshake or a frame.

--]]



--====================================================================--
--== Imports


local ByteArray = require 'lib.dmc_lua.lua_bytearray'
local ByteArrayError = require 'lib.dmc_lua.lua_bytearray.exceptions'
local Sockets = require 'dmc_sockets'
local urllib = require 'socket.url'

-- websocket modules
local ws_error = require 'dmc_websockets.exception'
local ws_frame = require 'dmc_websockets.frame'
local ws_handshake = require 'dmc_websockets.handshake'
local ws_message = require 'dmc_websockets.message'
local ws_utf8 = require 'dmc_websockets.utf8'



--====================================================================--
--== Setup, Constants


local sgmatch = string.gmatch
local tinsert = table.insert
local tconcat = table.concat

local ProtocolError = ws_error.ProtocolError
local BufferError = ByteArrayError.BufferError

local TEXT = 'text'

-- where a connection is
local CONNECTING = 'connecting' -- TCP (and TLS) not yet made
local HANDSHAKE = 'handshake' -- request sent, reading the response
local OPEN = 'open' -- frames

local LOCAL_DEBUG = false


local Native = {}

--== Throttle Constants

Native.OFF = Sockets.OFF
Native.LOW = Sockets.LOW
Native.MEDIUM = Sockets.MEDIUM
Native.HIGH = Sockets.HIGH

-- pings can be sent and are answered
Native.can_ping = true

Native.url = urllib



--====================================================================--
--== Connection Class
--====================================================================--


--[[
	Events given to onEvent:
	{ type='open' }
	{ type='message', data=<string>, ftype='text'|'binary' }
	{ type='ping', data=<string> }
	{ type='pong', data=<string> }
	{ type='close', code=<number>, reason=<string> } -- the server's close
	{ type='drop' } -- the socket closed, no closing handshake
	{ type='protocol_error', code=<number>, reason=<string> }
	{ type='error', kind='network'|'request'|'handshake'|'internal', emsg=<string> }
--]]

local Connection = {}
Connection.__index = Connection


-- send a whole message, kind 'text', 'binary', 'ping' or 'pong'
--
function Connection:send( kind, data )
	self:_sendFrame( ws_message{ opcode=ws_frame.type[ kind ], data=data } )
end

-- send a close frame: starts the closing handshake, or answers
-- the server's
--
function Connection:sendClose( code, reason )
	local data = ws_frame.encodeCloseFrameData( code, reason )
	self:_sendFrame( ws_message{ opcode=ws_frame.type.close, data=data } )
end

-- drop the connection: the socket is closed, nothing more is read
--
function Connection:close()
	if self._done then return end
	self._done = true
	self._socket:close()
	self._ba = nil
end


--== Private Methods

function Connection:_emit( event )
	self._onEvent( event )
end


function Connection:_doHttpConnect()
	-- print( "Connection:_doHttpConnect" )

	local request, key = ws_handshake.createRequest{
		host=self._host,
		port=self._port,
		path=self._path,
		protocols=self._protocols,
		origin=self._origin,
		user_agent=self._user_agent
	}

	self._ws_req_key = key

	if not request then
		self:_emit{ type='error', kind='request' }
		return
	end

	local callback = function( event )
		-- print("socket connect callback")
		if event.isError then
			self:_emit{ type='error', kind='request' }
		end
	end
	self._socket:send( request, callback )

end


-- @param str raw returned header from HTTP request
--
-- split up string into individual lines
--
function Connection:_processHeaderString( str )
	-- print( "Connection:_processHeaderString" )
	local results = {}
	for line in sgmatch( str, '([^\r\n]*)\r\n') do
		tinsert( results, line )
	end
	return results
end

-- add received data to the unread pieces; when the next frame (or
-- the handshake response) may be complete, join them into self._ba
-- and return true
--
function Connection:_bufferData( data )
	tinsert( self._rx_chunks, data )
	self._rx_len = self._rx_len + #data
	if self._rx_len < self._rx_need then return false end

	local ba = ByteArray:new()
	ba:writeBuf( tconcat( self._rx_chunks ) )
	self._ba = ba
	self._rx_chunks = {}
	self._rx_len = 0
	self._rx_need = 0
	return true
end

-- keep what self._ba holds unread for the next read, and note how much
-- the next frame needs, so it is parsed only once it has all arrived
--
function Connection:_keepUnread()
	local ba = self._ba
	if not ba then return end

	local avail = ba.bytesAvailable
	if avail == 0 then return end

	local rest = ba:readBuf( avail )
	tinsert( self._rx_chunks, 1, rest )
	self._rx_len = self._rx_len + #rest

	if self._phase == OPEN then
		self._rx_need = ws_frame.frameSize( rest ) or 0
	end
end

-- read header response string and see if it's valid
--
function Connection:_handleHttpRespose()
	-- print( "Connection:_handleHttpRespose" )
	local ba = self._ba

	-- first check if we have entire header to read
	local _, e_pos = ba:search( '\r\n\r\n' )
	if e_pos == nil then return end

	ba.position = 1
	local h_str = ba:readBuf( e_pos )

	-- process header
	if ws_handshake.checkResponse( self:_processHeaderString( h_str ), self._ws_req_key, self._protocols ) then
		self._phase = OPEN
		self:_emit{ type='open' }

		-- check if more data after reading header
		self:_receiveFrame()

	else
		self:_emit{ type='error', kind='handshake' }
	end

end


--== Methods to handle non-/fragmented frames

function Connection:_createNewFrame()
	self._current_frame = {
		data = {},
		type = '',
		utf8 = nil -- validator, text messages only
	}
end

function Connection:_insertFrameData( data, ftype )
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

	if ftype then
		frame.type = ftype
		if ftype == TEXT then
			frame.utf8 = ws_utf8.newValidator()
		end
	end
	tinsert( frame.data, data )

	return data
end

-- check text as it arrives, so invalid UTF-8 fails fast
--
function Connection:_validateFrameText( data, fin )
	local validator = self._current_frame.utf8
	if not validator then return end

	if not validator:feed( data ) or ( fin and not validator:isComplete() ) then
		local close = ws_frame.close.INVALID_DATA
		error( ProtocolError{
			code=close.code, reason=close.reason,
			message="Invalid UTF-8 in text message" } )
	end
end

-- the finished message, as an event
--
function Connection:_processCurrentFrame()
	local frame = self._current_frame
	self:_createNewFrame()
	return { type='message', data=tconcat( frame.data, '' ), ftype=frame.type }
end


function Connection:_receiveFrame()
	-- print( "Connection:_receiveFrame" )

	local ws_types = ws_frame.type
	local ws_close = ws_frame.close

	if self._done or self._phase ~= OPEN then
		-- dropped, or still in the handshake
		return
	end

	--== processing callback function

	local function handleWSFrame( frame_info )
		-- print("got frame", frame_info.type, frame_info.fin )
		-- print("got data", frame_info.data ) -- when testing, this could be A LOT of data
		local fcode, ftype, fin, data = frame_info.opcode, frame_info.type, frame_info.fin, frame_info.data

		if fcode == ws_types.continuation then
			if not self:_insertFrameData( data ) then
				error( ProtocolError{
					code=ws_close.PROTO_ERR.code, reason=ws_close.PROTO_ERR.reason,
					message="Continuation frame without a message to continue" } )
			end
			self:_validateFrameText( data, fin )
			if fin then
				self:_emit( self:_processCurrentFrame() )
			end

		elseif fcode == ws_types.text or fcode == ws_types.binary then
			if not self:_insertFrameData( data, ftype ) then
				error( ProtocolError{
					code=ws_close.PROTO_ERR.code, reason=ws_close.PROTO_ERR.reason,
					message="New message started before previous one finished" } )
			end
			self:_validateFrameText( data, fin )
			if fin then
				self:_emit( self:_processCurrentFrame() )
			end

		elseif fcode == ws_types.close then
			local code, reason = ws_frame.decodeCloseFrameData( data )
			self:_emit{
				type='close',
				code=code or ws_close.OK.code,
				reason=reason or ws_close.OK.reason
			}

		elseif fcode == ws_types.ping then
			self:_emit{ type='ping', data=data }

		elseif fcode == ws_types.pong then
			-- control frame: given now, it may arrive mid-message
			self:_emit{ type='pong', data=data }

		end
	end

	--== processing loop

	-- TODO: hook this up to enterFrame so large
	-- amount of frames won't pause processing

	local err = nil
	repeat

		local position = self._ba.position -- save in case of errors
		try{
			function()
				handleWSFrame( ws_frame.receiveFrame( self._ba ) )
			end,
			catch{
				function(e)
					err=e
					if self._ba then self._ba.position = position end
				end
			}
		}
	until err or self._done

	--== handle error
	if not err then
		-- pass, dropped

	elseif not err.isa then
		-- always print this out, most likely a regular Lua error
		print( "\n\ndmc_websockets :: Unknown Error", err )
		print( debug.traceback() )
		self:_emit{ type='error', kind='internal' }

	elseif err:isa( BufferError ) then
		-- pass, not enough data to read another frame

	elseif err:isa( ProtocolError ) then
		if LOCAL_DEBUG then
			print( "dmc_websockets :: Protocol Error:", err.message )
			print( "dmc_websockets :: Protocol Error:", err.traceback )
		end
		self:_emit{ type='protocol_error', code=err.code, reason=err.reason }

	else
		if LOCAL_DEBUG then
			print( "dmc_websockets :: Unknown Error", err.code, err.reason, err.message )
		end
		self:_emit{ type='error', kind='internal' }
	end

end

-- @param msg WebSocket Message object
--
function Connection:_sendFrame( msg )
	-- print( "Connection:_sendFrame", msg )

	msg.masked = true -- always when client to server

	local callback = function( event )
		-- print("socket send callback")
		if event.isError then
			self:_emit{ type='error', kind='network' }
		end
	end

	-- one frame takes the whole message
	-- TODO: add functionality to fragment a message (max_frame_size)
	local record = ws_frame.buildFrames{ message=msg }
	self._socket:send( record.frame, callback )

end


--== Socket Event Handlers

-- handle connection events from socket
--
function Connection:_socketConnectEvent_handler( event )
	-- print( "Connection:_socketConnectEvent_handler", event.type, event.status )
	if self._done then return end

	local sock = self._socket
	if event.type ~= sock.CONNECT then return end

	if self._phase == CONNECTING and event.status ~= sock.CONNECTED
		or event.isError
	then
		-- unreachable server, timeout, failed TLS handshake
		self:_emit{ type='error', kind='network', emsg=event.emsg }

	elseif event.status == sock.CONNECTED then
		if self._phase == CONNECTING then
			self._phase = HANDSHAKE
			self:_doHttpConnect()
		end

	else
		self:_emit{ type='drop' }

	end

end

-- handle read/write events from socket
--
function Connection:_socketDataEvent_handler( event )
	-- print( "Connection:_socketDataEvent_handler", event.type, event.status )
	if self._done then return end

	local sock = self._socket
	if event.type ~= sock.READ then return end

	local callback = function( s_event )
		local data = s_event.data
		if not data or data == '' then return end

		if not self:_bufferData( data ) then return end

		if self._phase == HANDSHAKE then
			-- the response header may come in more than one read
			self:_handleHttpRespose()
		else
			self:_receiveFrame()
		end

		self:_keepUnread()
	end

	sock:receive( '*a', callback )

end



--====================================================================--
--== Module Facade
--====================================================================--


-- the options every platform has: nothing to refuse here
--
function Native.checkParams( params )
end

-- how often sockets are read, shared by all of them
--
function Native.setThrottle( value )
	Sockets.throttle = value
end

-- open a connection
-- params: scheme, host, port, path (with its query), protocols, origin,
-- user_agent, ssl_params, onEvent (function)
--
function Native.connect( params )
	local conn = setmetatable( {
		_host=params.host,
		_port=params.port,
		_path=params.path,
		_protocols=params.protocols,
		_origin=params.origin,
		_user_agent=params.user_agent,
		_onEvent=params.onEvent,

		_phase=CONNECTING,
		_done=false,
		_ws_req_key='', -- key sent to server on handshake

		-- received data not yet parsed: pieces kept in a list and joined
		-- only once enough has arrived for the next frame, so a large
		-- message isn't copied again with every read
		_rx_chunks={},
		_rx_len=0,
		_rx_need=0, -- bytes needed before parsing is worth trying
		_ba=nil, -- our Byte Array, buffer

		_current_frame=nil, -- used to build a message from frames
		_socket=nil
	}, Connection )
	conn:_createNewFrame()

	local socket = Sockets:create( Sockets.ATCP, { ssl_params=params.ssl_params } )
	socket.secure = ( params.scheme == 'wss' ) -- true/false
	conn._socket = socket

	if LOCAL_DEBUG then
		print( "dmc_websockets:: Connecting to '" .. tostring( params.host ) .. ":" .. tostring( params.port ) .. "'" )
	end

	socket:connect( params.host, params.port, {
		onConnect=function( event ) conn:_socketConnectEvent_handler( event ) end,
		onData=function( event ) conn:_socketDataEvent_handler( event ) end
	} )

	return conn
end


return Native

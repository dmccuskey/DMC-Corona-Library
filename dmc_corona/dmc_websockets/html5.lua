--====================================================================--
-- dmc_corona/dmc_websockets/html5.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-websockets
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2026 Christian Kündig

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
--== DMC Corona Library : DMC WebSockets HTML5 Transport
--====================================================================--


--[[

An HTML5 build has no TCP sockets, so the browser's own WebSocket makes
the connection, the handshake and the frames, answers pings and does the
closing handshake. This module is the transport there, with the same
members as the native one (dmc_websockets/native.lua): it opens browser
connections through a small JavaScript bridge (html5_js.js, next to this
file) and hands the WebSocket class whole messages and the close.

The bridge keeps each connection's events in a queue, which is read here
from enterFrame (as often as the throttle allows). App code never runs
from inside a browser callback, and one connection's late events can't
reach another, since each has its own id.

Values cross the bridge as JSON, which carries only valid UTF-8 text, so
a binary message crosses as a string of characters U+0000-U+00FF, one per
byte (what the browser's atob() and btoa() use): a byte from 0x80 up is
two bytes of UTF-8 on the Lua side.

--]]


--====================================================================--
--== Setup, Constants


-- the bridge: dmc_corona/dmc_websockets/html5_js.js, which defines
-- window.dmc_corona_dmc_websockets_html5_js
local BRIDGE_MODULE = 'dmc_corona.dmc_websockets.html5_js'

local BROWSER_ERROR = "Browser WebSocket failed (browsers don't give the reason)"

local mfloor = math.floor
local schar = string.char
local sfind = string.find
local sgsub = string.gsub
local tinsert = table.insert
local tremove = table.remove
local type = type


-- a byte from 0x80 up <-> its character as UTF-8, U+0080-U+00FF
local TO_UTF8, FROM_UTF8 = {}, {}
for b = 0x80, 0xFF do
	local u = schar( 0xC0 + mfloor( b / 0x40 ), 0x80 + b % 0x40 )
	TO_UTF8[ schar( b ) ] = u
	FROM_UTF8[ u ] = schar( b )
end


local Html5 = {}

--== Throttle Constants, the same as the native transport
-- accepted but unused: connections are read every frame, since reading
-- the browser's queue costs next to nothing

Html5.OFF = 0
Html5.LOW = mfloor( 1000/30 )  -- ie, 30 FPS
Html5.MEDIUM = mfloor( 1000/15 )  -- ie, 15 FPS
Html5.HIGH = mfloor( 1000/1 )  -- ie, 1 FPS

-- browsers don't let scripts send pings, and answer the server's themselves
Html5.can_ping = false


local bridge = nil -- JS bridge module, loaded on first use

local connections = {} -- open connections, in the order opened
local reading = false -- enterFrame listener added



--====================================================================--
--== Support Functions


-- URLs, without LuaSocket's socket.url (not in HTML5 builds)

local function escape( str )
	-- same as LuaSocket's url.escape
	return ( str:gsub( "([^A-Za-z0-9_])", function( c )
		return string.format( "%%%02x", string.byte( c ) )
	end ) )
end

-- ws://host:port/path?query, the parts dmc_websockets uses
--
local function parse( uri )
	local parts = {}
	local scheme, rest = uri:match( '^(%a[%w+.-]*)://(.*)$' )
	if not scheme then return parts end
	parts.scheme = scheme:lower()

	rest = rest:gsub( '#.*$', '' )
	local authority, path = rest:match( '^([^/?]*)(.*)$' )
	authority = authority:gsub( '^.*@', '' ) -- no user info

	local host, port
	if authority:sub( 1, 1 ) == '[' then
		host, port = authority:match( '^%[([^%]]*)%]:?(%d*)$' )
	else
		host, port = authority:match( '^([^:]*):?(%d*)$' )
	end
	parts.host = host
	parts.port = tonumber( port )

	local query
	path, query = path:match( '^([^?]*)%??(.*)$' )
	parts.path = path
	if query ~= '' then parts.query = query end

	return parts
end

Html5.url = {
	escape=escape,
	parse=parse
}


local function loadBridge()
	if bridge then return bridge end

	local ok, mod = pcall( require, BRIDGE_MODULE )
	if not ok or type( mod ) ~= 'table' then
		return nil, "HTML5 bridge not found, expected dmc_corona/dmc_websockets/html5_js.js"
	end
	bridge = mod
	return bridge
end

-- message from a failed bridge call
--
local function bridgeError( result )
	local err = type( result ) == 'table' and result.error
	if type( err ) ~= 'table' then return "HTML5 bridge call failed" end
	return tostring( err.name ) .. ": " .. tostring( err.message )
end


local function readAll()
	-- a listener may open or close connections while we go
	local list = {}
	for i = 1, #connections do list[i] = connections[i] end
	for i = 1, #list do
		local conn = list[i]
		if not conn._done then conn:_read() end
	end

	if #connections == 0 and reading then
		Runtime:removeEventListener( 'enterFrame', readAll )
		reading = false
	end
end

local function startReading()
	if reading then return end
	Runtime:addEventListener( 'enterFrame', readAll )
	reading = true
end



--====================================================================--
--== Connection Class
--====================================================================--


--[[
	Events given to onEvent:
	{ type='open' }
	{ type='message', data=<string>, ftype='text'|'binary' }
	{ type='close', code=<number>, reason=<string>, wasClean=<boolean> }
	{ type='error', kind='network', emsg=<string> } -- failed, no details
	{ type='error', kind='internal' } -- an error in app code run from an event
--]]

local Connection = {}
Connection.__index = Connection


-- send a whole message, ftype 'text' or 'binary'
-- text must be valid UTF-8 (checked in WebSocket:send)
--
function Connection:send( ftype, data )
	if not self._id then return end
	-- pings and pongs aren't sent in HTML5 builds
	if ftype ~= 'text' and ftype ~= 'binary' then return end

	local params = { id=self._id, type=ftype, data=data }
	if ftype == 'binary' then
		params.data = sgsub( data, '[\128-\255]', TO_UTF8 )
	end

	local result = bridge.send( params )
	if type( result ) == 'table' and result.ok then return end

	local err = type( result ) == 'table' and result.error
	if type( err ) == 'table' and err.kind == 'not_open' then
		-- closing or closed: the close event is on its way
		return
	end
	self:_fail( bridgeError( result ) )
end

-- start the browser's closing handshake. Scripts may only send
-- code 1000 or 3000-4999, so for any other the browser picks
--
function Connection:sendClose( code, reason )
	if not self._id then return end

	local params = { id=self._id }
	if code == 1000 or ( type( code ) == 'number' and code >= 3000 and code <= 4999 ) then
		params.code = code
		params.reason = reason or ''
	end
	local result = bridge.close( params )
	if type( result ) ~= 'table' or not result.ok then
		self:_fail( bridgeError( result ) )
	end
end

-- drop the connection: no more events, the browser socket is closed
--
function Connection:close()
	if self._done then return end
	self._done = true
	self._onEvent = nil
	self._pending = {}

	if self._id then
		bridge.dispose{ id=self._id }
		self._id = nil
	end

	for i = #connections, 1, -1 do
		if connections[i] == self then tremove( connections, i ) end
	end
end


--== Private Methods

function Connection:_deliver( event )
	local onEvent = self._onEvent
	if not onEvent then return end

	-- as with frames from a socket, an error in app code fails the connection
	local ok, err = xpcall( function() onEvent( event ) end, debug.traceback )
	if not ok then
		print( "\n\ndmc_websockets :: Unknown Error", err )
		if not self._done then onEvent{ type='error', kind='internal' } end
	end
end

-- fail from the next read, after any events already queued
--
function Connection:_fail( emsg )
	if self._failed then return end
	self._failed = true
	tinsert( self._pending, { type='error', kind='network', emsg=emsg } )
end

function Connection:_read()
	if self._id and not self._failed then
		local result = bridge.poll{ id=self._id }
		if type( result ) == 'table' and result.ok then
			local events = result.events or {}
			for i = 1, #events do
				self:_browserEvent( events[i] )
				if self._done or self._failed then break end
			end
		else
			self:_fail( bridgeError( result ) )
		end
	end

	while #self._pending > 0 and not self._done do
		self:_deliver( tremove( self._pending, 1 ) )
	end
end

function Connection:_browserEvent( event )
	local kind = event.kind

	if kind == 'open' then
		self._opened = true
		self:_deliver{ type='open' }

	elseif kind == 'message' then
		local data = event.data
		if event.type == 'binary' then
			data = data or ''
			if sfind( data, '[\196-\255]' ) then
				self:_fail( "HTML5 bridge sent a character above U+00FF in binary data" )
				return
			end
			data = sgsub( data, '[\194\195][\128-\191]', FROM_UTF8 )
		end
		self:_deliver{ type='message', data=data, ftype=event.type }

	elseif kind == 'error' then
		-- browsers report an error, then close with 1006
		self._error = true

	elseif kind == 'close' then
		if self._error or event.code == 1006 or not self._opened then
			-- unreachable server, refused handshake, failed TLS or a
			-- dropped connection: browsers don't say which
			self:_deliver{ type='error', kind='network', emsg=BROWSER_ERROR }
		else
			self:_deliver{ type='close', code=event.code, reason=event.reason,
				wasClean=event.wasClean }
		end

	end
end



--====================================================================--
--== Module Facade
--====================================================================--


-- the options a browser doesn't leave to scripts: it makes the
-- handshake and does TLS itself
--
function Html5.checkParams( params )
	assert( type( params.keepalive ) ~= 'number' or params.keepalive <= 0,
		"WebSocket: 'keepalive' isn't available in HTML5 builds" )
	assert( params.origin == nil,
		"WebSocket: 'origin' isn't available in HTML5 builds, the browser sends its own" )
	assert( params.ssl_params == nil,
		"WebSocket: 'ssl_params' isn't available in HTML5 builds" )
end

-- accepted but unused, see Throttle Constants
--
function Html5.setThrottle( value )
end

-- open a connection
-- params: scheme, host, port, path (with its query), protocols (a string
-- or a list of them), onEvent (function)
--
function Html5.connect( params )
	local host = params.host
	if host:find( ':', 1, true ) then host = '[' .. host .. ']' end -- IPv6
	local url = params.scheme .. '://' .. host .. ':' .. params.port .. params.path

	local protocols = params.protocols
	if type( protocols ) == 'string' then protocols = { protocols } end

	local conn = setmetatable( {
		_id=nil,
		_onEvent=params.onEvent,
		_pending={}, -- events made here, delivered on the next read
		_opened=false,
		_error=false,
		_failed=false,
		_done=false
	}, Connection )

	local b, emsg = loadBridge()
	if b then
		local result = b.open{ url=url, protocols=protocols or {} }
		if type( result ) == 'table' and result.ok then
			conn._id = result.id
		else
			-- eg an invalid URL, or ws:// from an https:// page
			emsg = bridgeError( result )
		end
	else
		print( "WARNING :: dmc_websockets: " .. emsg )
	end
	if not conn._id then conn:_fail( emsg ) end

	tinsert( connections, conn )
	startReading()

	return conn
end


return Html5

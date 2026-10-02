--====================================================================--
-- dmc_corona/dmc_netstream.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-netstream
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
--== DMC Corona Library : Net Stream
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.5.0"



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
--== DMC NetStream
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_netstream = dmc_lib_data.dmc_netstream or {}

local DMC_NETSTREAM_DEFAULTS = {
	debug_active=false,
}

local dmc_netstream_data = Utils.extend( dmc_lib_data.dmc_netstream, DMC_NETSTREAM_DEFAULTS )



--====================================================================--
--== Imports


local UrlLib = require 'socket.url'

local Objects = require 'lib.dmc_lua.lua_objects'
local Patch = require 'dmc_patch'
local Sockets = require 'dmc_sockets'
local StatesMixModule = require 'dmc_states_mix'



--====================================================================--
--== Setup, Constants


Patch.addPatch( 'string-format' )

local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase
local StatesMix = StatesMixModule.StatesMix

local sfind = string.find
local slower = string.lower
local smatch = string.match
local ssub = string.sub
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local type = type
local pairs = pairs

local NetStream -- forward
local netstream_table = {}

local DEFAULT_PORT = 80
local DEFAULT_SPORT = 443

-- how the end of the response body is found
local BODY_CLOSE = 'close' -- the server closes the connection
local BODY_LENGTH = 'length' -- Content-Length
local BODY_CHUNKED = 'chunked' -- Transfer-Encoding: chunked



--====================================================================--
--== Support Functions


-- make up a generic request for the web server
--
local function createNetStream( params )
	-- print( "createNetStream" )
	params = params or {}
	--==--

	local ns = NetStream:new{
		url = params.url,
		method = params.method,
		listener = params.listener,
		http_params = params.params,
		auto_connect = params.auto_connect
	}

	netstream_table[ ns ] = ns
	return ns
end

local function removeNetStream( netstream, event )
	-- print( "removeNetStream" )

	local ns = netstream_table[ netstream ]
	if ns then
		ns:removeSelf()
	end
end

local function createHttpRequest( params )
	-- print( "NetStream:createHttpRequest")
	params = params or {}
	--==--
	local http_params = params.http_params
	local headers = params.headers
	local body = http_params.body

	if body ~= nil and headers['content-length'] == nil then
		headers['content-length'] = #body
	end

	local req_t = {
		"%s %s HTTP/1.1" % { params.method, params.path },
		"Host: %s" % params.host,
	}

	for k,v in pairs( headers ) do
		tinsert( req_t, "%s: %s" % { k, tostring( v ) } )
	end

	-- the headers end with an empty line, then the body
	local req = tconcat( req_t, "\r\n" ) .. "\r\n\r\n"
	if body ~= nil then
		req = req .. body
	end

	return req
end


-- parseResponseHead()
-- reads the status line and headers (without the empty line after them)
-- returns status code, reason, headers (names lower-cased), or nil on error
--
local function parseResponseHead( str )
	local lines = {}
	for line in ( str .. "\n" ):gmatch( "([^\n]*)\n" ) do
		if ssub( line, -1 ) == "\r" then line = ssub( line, 1, -2 ) end
		tinsert( lines, line )
	end

	local code, reason = smatch( lines[1] or "", "^HTTP/%d+%.%d+%s+(%d%d%d)%s*(.*)$" )
	if not code then return nil end

	local headers = {}
	for i = 2, #lines do
		local name, value = smatch( lines[i], "^([^:%s]+)%s*:%s*(.-)%s*$" )
		if name then
			name = slower( name )
			if headers[ name ] then
				headers[ name ] = headers[ name ] .. ", " .. value
			else
				headers[ name ] = value
			end
		end
	end

	return tonumber( code ), reason, headers
end



--====================================================================--
--== Net Stream Class
--====================================================================--


NetStream = newClass( { ObjectBase, StatesMix }, { name="DMC NetStream" } )

--== Class Constants

NetStream.VERSION = VERSION
NetStream.USER_AGENT = 'dmc-netstream %s' % VERSION

--== State Constants

NetStream.STATE_CREATE = 'state_create'
NetStream.STATE_NOT_CONNECTED = 'state_not_connected'
NetStream.STATE_CONNECTING = 'state_connecting'
NetStream.STATE_CONNECTED = 'state_connected'

--== Event Constants

NetStream.EVENT = 'dmc_netstream_event'

NetStream.CONNECTING = 'netstream_connecting_event'
NetStream.CONNECTED = 'netstream_connected_event'
NetStream.DATA = 'netstream_data_event'
NetStream.DISCONNECTED = 'netstream_disconnected_event'
NetStream.ERROR = 'netstream_error_event'

--== Error Messages

NetStream.ERR_BAD_RESPONSE = 'bad response'


--======================================================--
-- Start: Setup Lua Objects

function NetStream:__init__( params )
	-- print( "NetStream:__init__", params )
	params = params or {}
	self:superCall( ObjectBase, '__init__', params )
	self:superCall( StatesMix, '__init__', params )
	--==--

	--== Create Properties ==--

	self._url = params.url
	self._method = params.method or 'GET'
	self._listener = params.listener
	self._http_params = params.http_params or {}

	self._auto_connect = params.auto_connect ~= false

	-- event listeners
	self._onConnect_f = nil
	self._onData_f = nil

	-- from URL
	self._host = ""
	self._port = 0
	self._path = ""
	self._default_port = DEFAULT_PORT

	-- response
	self._status = nil
	self._headers = nil
	self._buffer = "" -- received data not yet passed on
	self._body_mode = nil -- BODY_CLOSE, BODY_LENGTH, BODY_CHUNKED
	self._body_left = nil -- bytes left, for BODY_LENGTH
	self._chunk_left = nil -- bytes left in the chunk; nil when a size line is next

	self._start_timer = nil
	self._finish_timer = nil
	self._sock = nil

end


function NetStream:__initComplete__()
	-- print( "NetStream:__initComplete__" )
	self:superCall( ObjectBase, '__initComplete__' )
	--==--

	local url_parts = UrlLib.parse( self._url )
	local is_secure = url_parts.scheme == 'https'

	self._default_port = is_secure and DEFAULT_SPORT or DEFAULT_PORT
	self._host = url_parts.host
	self._port = tonumber( url_parts.port )
	self._path = url_parts.path

	if self._port == nil or self._port == 0 then
		self._port = self._default_port
	end
	if self._path == nil or self._path == '' then
		self._path = '/'
	end
	if url_parts.query then
		self._path = self._path .. '?' .. url_parts.query
	end

	self._onConnect_f=self:createCallback( self._onConnect_handler )
	self._onData_f=self:createCallback( self._onData_handler )

	self._sock = Sockets:create( Sockets.ATCP )
	-- SSL secure socket
	self._sock.secure = is_secure


	-- set first state and transition
	self:setState( self.STATE_CREATE )

	-- delay so that event listeners can be setup by user
	-- in time to get events
	self._start_timer = timer.performWithDelay( 1, function()
		self._start_timer = nil
		self:gotoState( self.STATE_NOT_CONNECTED )
	end )

end

function NetStream:__undoInitComplete__()
	-- print( "NetStream:__undoInitComplete__" )
	local o

	netstream_table[ self ] = nil

	if self._start_timer then
		timer.cancel( self._start_timer )
		self._start_timer = nil
	end
	if self._finish_timer then
		timer.cancel( self._finish_timer )
		self._finish_timer = nil
	end

	o = self._sock
	if o and o.removeSelf then o:removeSelf() end
	self._sock = nil

	--==--
	self:superCall( ObjectBase, '__undoInitComplete__' )
end

-- END: Setup Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


-- the response's status code, once the headers are in
--
function NetStream.__getters:status()
	return self._status
end

-- the response's headers (names lower-cased), once they are in
--
function NetStream.__getters:headers()
	return self._headers
end


-- connect()
-- starts a stream created with auto_connect=false
--
function NetStream:connect()
	-- print( "NetStream:connect" )
	if not self._sock then return end -- finished
	self._auto_connect = true
	if self:getState() == self.STATE_NOT_CONNECTED then
		self:gotoState( self.STATE_CONNECTING )
	end
end



--====================================================================--
--== State Machine


--== CREATE ==--

function NetStream:state_create( next_state, params )
	-- print( "NetStream:state_create: >> ", next_state )

	if next_state == NetStream.STATE_NOT_CONNECTED then
		self:do_state_not_connected( params )

	else
		print( "WARNING :: NetStream:state_create " .. tostring( next_state ) )
	end
end

--== NOT CONNECTED ==--

function NetStream:do_state_not_connected( params )
	-- print( "NetStream:do_state_not_connected" )
	params = params or {}
	--==--
	local event = params.event or nil -- might get event here

	-- set state first so we can go to another
	self:setState( self.STATE_NOT_CONNECTED )

	if params.failed then
		-- the error has been reported, the stream is finished

	elseif event then
		-- we're coming from being connected
		self:_send( nil, event.emsg )

		self:dispatchEvent( self.DISCONNECTED, { emsg=event.emsg }, {merge=true} )

	else
		-- haven't connected yet
		if self._auto_connect == true then
			self:gotoState( self.STATE_CONNECTING )
		end
	end

end

function NetStream:state_not_connected( next_state, params )
	-- print( "NetStream:state_not_connected: >> ", next_state )

	if next_state == NetStream.STATE_CONNECTING then
		self:do_state_connecting( params )

	else
		print( "WARNING :: NetStream:state_not_connected " .. tostring( next_state ) )
	end
end

--== CONNECTING ==--

function NetStream:do_state_connecting( params )
	-- print( "NetStream:do_state_connecting" )
	params = params or {}
	--==--
	params.onConnect = self._onConnect_f
	params.onData = self._onData_f

	-- set state first so we can go to another
	self:setState( self.STATE_CONNECTING )

	self:dispatchEvent( self.CONNECTING )

	self._sock:connect( self._host, self._port, params )

end

function NetStream:state_connecting( next_state, params )
	-- print( "NetStream:state_connecting: >> ", next_state )

	if next_state == NetStream.STATE_CONNECTED then
		self:do_state_connected( params )

	elseif next_state == NetStream.STATE_NOT_CONNECTED then
		self:do_state_not_connected( params )

	else
		print( "WARNING :: NetStream:state_connecting " .. tostring( next_state ) )
	end
end

--== CONNECTED ==--

function NetStream:do_state_connected( params )
	-- print( "NetStream:do_state_connected" )
	params = params or {}
	--==--

	-- set state first so we can go to another
	self:setState( self.STATE_CONNECTED )

	self:dispatchEvent( self.CONNECTED, { status=self._status, headers=self._headers }, {merge=true} )

end

function NetStream:state_connected( next_state, params )
	-- print( "NetStream:state_connected: >> ", next_state )

	if next_state == NetStream.STATE_NOT_CONNECTED then
		self:do_state_not_connected( params )

	else
		print( "WARNING :: NetStream:state_connected " .. tostring( next_state ) )
	end
end



--====================================================================--
--== Private Methods


--[[
Chunk contains the current chunk of data. When the transmission is over,
the function is called with an empty string (i.e. "") as the chunk.
If an error occurs, the function receives 'nil' as chunk and an error
message as 'err'
--]]
function NetStream:_send( data, emsg )
	-- print("NetStream:_send", #data )
	if self._listener then self._listener( { data=data, emsg=emsg } ) end
end


function NetStream:_handleErrorEvent( event )
	-- print("NetStream:_handleErrorEvent", event )

	self:_send( nil, event.emsg )
	self:dispatchEvent( self.ERROR, { emsg=event.emsg }, {merge=true} )

	self:gotoState( self.STATE_NOT_CONNECTED, { failed=true } )

end

-- a response we can't read: report it and stop the stream
--
function NetStream:_fail( emsg )
	-- print("NetStream:_fail", emsg )
	self:_handleErrorEvent( { emsg=emsg } )
	removeNetStream( self )
end


-- passes a piece of the response body to the user
--
function NetStream:_deliver( data )
	if data == '' then return end
	self:_send( data, nil )
	-- the listener may have stopped the stream
	if not self._sock then return end
	self:dispatchEvent( self.DATA, { data=data }, {merge=true} )
end


-- the whole body is in: close the connection, which ends the
-- stream with DISCONNECTED. Done on the next frame, since we
-- are inside the socket's read
--
function NetStream:_finishBody()
	-- print("NetStream:_finishBody" )
	if self._finish_timer then return end
	self._finish_timer = timer.performWithDelay( 1, function()
		self._finish_timer = nil
		if self._sock then self._sock:close() end
	end )
end


-- reads the status line and headers from the buffer, once they are
-- all in; returns the data that came after them, or nil
--
function NetStream:_readResponseHead()
	local buf = self._buffer
	local s, e = sfind( buf, "\r\n\r\n", 1, true )
	local s2, e2 = sfind( buf, "\n\n", 1, true )
	if s2 and ( not s or s2 < s ) then s, e = s2, e2 end
	if not s then return nil end

	local code, reason, headers = parseResponseHead( ssub( buf, 1, s-1 ) )
	if not code then
		self:_fail( self.ERR_BAD_RESPONSE )
		return nil
	end
	local rest = ssub( buf, e+1 )
	self._buffer = ""

	-- skip an interim response (100 Continue), the real one follows
	if code >= 100 and code < 200 then
		self._buffer = rest
		return self:_readResponseHead()
	end

	self._status = code
	self._headers = headers

	local te = slower( headers['transfer-encoding'] or "" )
	local length = tonumber( headers['content-length'] )

	if self._method == 'HEAD' or code == 204 or code == 304 then
		self._body_mode, self._body_left = BODY_LENGTH, 0
	elseif sfind( te, 'chunked', 1, true ) then
		self._body_mode = BODY_CHUNKED
	elseif length then
		self._body_mode, self._body_left = BODY_LENGTH, length
	else
		self._body_mode = BODY_CLOSE
	end

	return rest
end


-- decodes a chunked body; returns the data and whether the
-- last chunk has arrived
--
function NetStream:_decodeChunks( data )
	local buf = self._buffer .. data
	local out = {}
	local done = false

	while true do
		local left = self._chunk_left

		if left == nil then
			-- a size line: hex size, maybe extensions, CRLF
			local s, e = sfind( buf, "\n", 1, true )
			if not s then break end
			local size = tonumber( smatch( ssub( buf, 1, s-1 ), "^%s*(%x+)" ) or "", 16 )
			if not size then return nil end -- not chunked data
			buf = ssub( buf, e+1 )
			if size == 0 then
				-- last chunk; trailers are ignored
				buf, done = "", true
				break
			end
			self._chunk_left = size

		elseif left > 0 then
			if buf == "" then break end
			local piece = ssub( buf, 1, left )
			tinsert( out, piece )
			self._chunk_left = left - #piece
			buf = ssub( buf, #piece+1 )

		else
			-- the line end after the chunk's data
			local s, e = sfind( buf, "\n", 1, true )
			if not s then break end
			buf = ssub( buf, e+1 )
			self._chunk_left = nil

		end
	end

	self._buffer = buf
	return tconcat( out ), done
end


-- handles data received from the socket
--
function NetStream:_processData( data )
	-- print("NetStream:_processData", #data )

	if self:getState() == self.STATE_CONNECTING then
		self._buffer = self._buffer .. data
		data = self:_readResponseHead()
		if data == nil then return end -- need more, or failed
		self:gotoState( self.STATE_CONNECTED )
		if not self._sock then return end -- stopped in CONNECTED
	end

	local mode, done = self._body_mode, false

	if mode == BODY_CHUNKED then
		data, done = self:_decodeChunks( data )
		if data == nil then
			self:_fail( self.ERR_BAD_RESPONSE )
			return
		end

	elseif mode == BODY_LENGTH then
		data = ssub( data, 1, self._body_left )
		self._body_left = self._body_left - #data
		done = self._body_left == 0

	end

	self:_deliver( data )
	if done and self._sock then self:_finishBody() end
end



--====================================================================--
--== Event Handlers


function NetStream:_onConnect_handler( event )
	-- print("NetStream:_onConnect_handler", event.status )

	local sock = self._sock

	if event.status == sock.CONNECTED then
		-- print("=== Connection Established ===")

		local http_params = self._http_params or {}
		local headers = Utils.normalizeHeaders( http_params.headers or {}, {case='lower'} )
		headers['user-agent'] = headers['user-agent'] or self.USER_AGENT

		local host = self._host
		if self._port ~= self._default_port then
			host = host .. ':' .. tostring( self._port )
		end

		local p = {
			host=host,
			method=self._method,
			path=self._path,
			headers=headers,
			http_params=http_params
		}

		sock:send( createHttpRequest( p ) )

	elseif event.status == sock.CLOSED then
		-- print("=== Connection Closed ===\n\n")
		-- print( event.emsg )

		self:gotoState( self.STATE_NOT_CONNECTED, { event=event } )
		removeNetStream( self )

	else
		-- print("=== Connection Error ===")
		self:_handleErrorEvent( event )
		removeNetStream( self, event )

	end

end


function NetStream:_onData_handler( event )
	-- print("NetStream:_onData_handler", event.status )
	event = event or {}
	--==--

	local state = self:getState()
	if state ~= self.STATE_CONNECTING and state ~= self.STATE_CONNECTED then return end

	self._sock:receive( '*a', function( e )
		if e.data and e.data ~= '' then self:_processData( e.data ) end
	end )

end




--====================================================================--
--== NetStream Facade
--====================================================================--


return {
	newStream = createNetStream,
}

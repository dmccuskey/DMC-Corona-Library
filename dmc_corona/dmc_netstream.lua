--====================================================================--
-- dmc_netstream.lua
--
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_netstream.lua
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

local VERSION = "0.3.0"



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

local Objects = require 'dmc_objects'
local Patch = require 'dmc_patch'
local Sockets = require 'dmc_sockets'
local StatesMixModule = require 'dmc_states_mix'
local Utils = require 'dmc_utils'



--====================================================================--
--== Setup, Constants


Patch.addPatch( 'string-format' )

local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local StatesMix = StatesMixModule.StatesMix

local tconcat = table.concat
local tinsert = table.insert

local NetStream -- forward
local netstream_table = {}

local DEFAULT_PORT = 80
local DEFAULT_SPORT = 443



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
		http_params = params.params
	}

	netstream_table[ ns ] = ns
	return ns
end

local function removeNetStream( netstream, event )
	-- print( "removeNetStream" )

	local ns = netstream_table[ netstream ]
	if ns then
		netstream_table[ netstream ] = nil
		ns:removeSelf()
	end
end

function createHttpRequest( params )
	-- print( "NetStream:createHttpRequest")
	params = params or {}
	--==--
	local http_params = params.http_params
	local req_t = {
		"%s %s HTTP/1.1" % { params.method, params.path },
		"Host: %s" % params.host,
	}

	if type( http_params.headers ) == 'table' then
		for k,v in pairs( http_params.headers ) do
			tinsert( req_t, #req_t+1, "%s: %s" % { k, v } )
		end
	end

	if http_params.body ~= nil then
		tinsert( req_t, #req_t+1, "" )
		tinsert( req_t, #req_t+1, http_params.body )
	end
	tinsert( req_t, #req_t+1, "\r\n" )

	-- print( tconcat( req_t, "\r\n" ) )
	return tconcat( req_t, "\r\n" )
end



--====================================================================--
--== Net Stream Class
--====================================================================--


NetStream = newClass( { ObjectBase, StatesMix }, { name="DMC NetStream" } )

--== Class Constants

NetStream.VERSION = VERSION

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


--======================================================--
-- Start: Setup DMC Objects

function NetStream:__init__( params )
	-- print( "NetStream:__init__", params )
	params = params or {}
	self:superCall( StatesMix, '__init__', params )
	self:superCall( ObjectBase, '__init__', params )
	--==--

	-- Utils.print( params )

	--== Create Properties ==--

	self._url = params.url
	self._method = params.method or 'GET'
	self._listener = params.listener
	self._http_params = params.http_params or {}

	self._auto_connect = params.auto_connect ~= nil and params.auto_connect or true

	self._header_wait = false

	-- event listeners
	self._onConnect_f = nil
	self._onData_f = nil

	-- from URL
	self._host = ""
	self._port = 0
	self._path = ""

end


function NetStream:__initComplete__()
	-- print( "NetStream:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--

	local url_parts = UrlLib.parse( self._url )

	self._host = url_parts.host
	self._port = url_parts.port
	self._path = url_parts.path

	if self._port == nil or self._port == 0 then
		self._port = url_parts.scheme == 'https' and DEFAULT_SPORT or DEFAULT_PORT
	end
	if self._path == nil then
		self._path = '/'
	end

	self._onConnect_f=self:createCallback( self._onConnect_handler )
	self._onData_f=self:createCallback( self._onData_handler )

	self._sock = Sockets:create( Sockets.ATCP )
	-- SSL secure socket
	self._sock.secure = url_parts.scheme == 'https' and true or false


	-- set first state and transition
	self:setState( self.STATE_CREATE )

	-- delay so that event listeners can be setup by user
	-- in time to get events
	timer.performWithDelay( 1, function() self:gotoState( self.STATE_NOT_CONNECTED ) end )

end

function NetStream:__undoInitComplete__()
	-- print( "NetStream:__undoInitComplete__" )

	local o

	o = self._sock
	if o.removeSelf then o:removeSelf() end
	self._sock = nil

	--==--
	self:superCall( '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function NetStream:connect()
	-- print( "NetStream:connect" )
	if self:getState() == self.NOT_CONNECTED then
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

	if event then
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
	self._header_wait = false

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

	self:dispatchEvent( self.CONNECTED )

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

	self:gotoState( self.STATE_NOT_CONNECTED )

end


--====================================================================--
--== Event Handlers


function NetStream:_onConnect_handler( event )
	-- print("NetStream:_onConnect_handler", event.status )

	local sock = self._sock
	local user_agent = 'dmc-netstream %s' % tostring( NetStream.VERSION )

	if event.status == sock.CONNECTED then
		-- print("=== Connection Established ===")

		local http_params, http_header
		http_params = self._http_params or {}
		http_header = http_params.headers or {}
		http_header = Utils.normalizeHeaders( http_header, {case='lower'} )
		http_header['user-agent'] = http_header['user-agent'] or user_agent
		http_params.headers = http_header -- put back

		local p = {
			host=self._host,
			method=self._method,
			path=self._path,
			http_params = http_params
		}

		local bytes, err = sock:send( createHttpRequest( p ) )

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
	-- print( '>>', event.type, event.status, event.bytes )
	--==--

	local curr_state = self:getState()

	local connecting_handler = function( e )
		-- print("== Newline Handler ==")

		if not e.data then
			-- print( 'err>>', event.emsg )
			self:_handleErrorEvent( event )
			removeNetStream( self )

		else
			-- print("Received Data:\n")
			-- for i,v in ipairs( e.data ) do print(i,v) end
			-- print("\n")
			self._header_wait = false
			self:gotoState( self.STATE_CONNECTED )

		end
	end

	local connected_handler = function( e )
		-- print("=== Data Event ===\n\n")
		-- print( 'data re>> ', e.data, e.emsg )
		-- Utils.hexDump( e.data )
		if e.data ~= nil then
			self:_send( e.data, e.emsg )
			self:dispatchEvent( self.DATA, { data=e.data, emsg=event.emsg }, {merge=true} )
		end
	end

	if curr_state == self.STATE_CONNECTING and not self._header_wait then
		self._sock:receiveUntilNewline( connecting_handler )
		self._header_wait = true

	elseif curr_state == self.STATE_CONNECTED then
		self._sock:receive( '*a', connected_handler  )

	end

end




--====================================================================--
--== NetStream Facade
--====================================================================--


return {
	newStream = createNetStream,
}



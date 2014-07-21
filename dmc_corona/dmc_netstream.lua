--====================================================================--
-- dmc_netstream.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_netstream.lua
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014 David McCuskey

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
-- DMC Corona Library : Net Stream
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local UrlLib = require 'socket.url'

local Objects = require 'lua_objects'
local Patch = require('lua_patch')('string-format')
local Sockets = require 'dmc_corona.dmc_sockets'
local Utils = require 'lua_utils'


--====================================================================--
-- Setup, Constants

local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase

local tconcat = table.concat
local tinsert = table.insert

local NetStream -- forward
local netstream_table = {}


--====================================================================--
-- Support Functions

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
-- Net Stream Class
--====================================================================--


NetStream = inheritsFrom( ObjectBase )
NetStream.NAME = "HTTP Streamer"

NetStream.VERSION = VERSION


NetStream.EVENT = 'dmc_netstream_event'
NetStream.DATA = 'netstream_data_event'
NetStream.CONNECTED = 'netstream_connected_event'
NetStream.DISCONNECTED = 'netstream_disconnected_event'
NetStream.ERROR = 'netstream_error_event'


--====================================================================--
--== Start: Setup DMC Objects

function NetStream:_init( params )
	-- print( "NetStream:_init", params )
	params = params or {}
	self:superCall( '_init', params )
	--==--

	-- Utils.print( params )

	--== Create Properties ==--

	self._url = params.url
	self._method = params.method or 'GET'
	self._listener = params.listener
	self._http_params = params.http_params or {}

	-- from URL
	self._host = ""
	self._port = 0
	self._path = ""

end


function NetStream:_initComplete()
	-- print( "NetStream:_initComplete" )
	self:superCall( '_initComplete' )
	--==--

	local url_parts = UrlLib.parse( self._url )

	self._host = url_parts.host
	self._port = url_parts.port
	self._path = url_parts.path

	if self._port == nil or self._port == 0 then
		self._port = url_parts.scheme == 'https' and 443 or 80
	end
	if self._path == nil then
		self._path = '/'
	end

	local params = {
		onConnect=self:createCallback( self._onConnect_handler ),
		onData=self:createCallback( self._onData_handler )
	}
	self._sock = Sockets:create( Sockets.ATCP )
	-- SSL secure socket
	self._sock.secure = url_parts.scheme == 'https' and true or false

	self._sock:connect( self._host, self._port, params )

end

function NetStream:_undoInitComplete()
	-- print( "NetStream:_undoInitComplete" )

	local o

	o = self._sock
	if o.removeSelf then o:removeSelf() end
	self._sock = nil

	--==--
	self:superCall( '_undoInitComplete' )
end

--== END: Setup DMC Objects
--====================================================================--


--====================================================================--
--== Public Methods

-- none


--====================================================================--
--== Private Methods

--[[
Chunk contains the current chunk of data. When the transmission is over, the function is called with an empty string (i.e. "") as the chunk. If an error occurs, the function receives nil as chunk and an error message as err
--]]
function NetStream:_send( data, emsg )
	-- print("NetStream:_send", #data )
	if self._listener then self._listener( { data=data, emsg=emsg } ) end
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

		local newlineCallback = function(e)
			-- print("== Newline Handler ==")

			if not e.data then
				-- print( 'err>>', event.emsg )
				self:_send( nil, event.emsg )
				self:dispatchEvent( self.ERROR, { emsg=event.emsg } )
				removeNetStream( self )

			else
				-- print("Received Data:\n")
				-- for i,v in ipairs( e.data ) do
				-- 	print(i,v)
				-- end
				-- print("\n")

			end
			if sock.buffer_size > 0 then
				self:_onData_handler()
			end
		end
		sock:receiveUntilNewline( newlineCallback )

		self:dispatchEvent( self.CONNECTED )

	elseif event.status == sock.CLOSED then
		-- print("=== Connection Closed ===\n\n")
		-- print( event.emsg )
		self:_send( nil, event.emsg )
		self:dispatchEvent( self.DISCONNECTED, { emsg=event.emsg } )
		removeNetStream( self )

	else
		-- print("=== Connection Error ===")
		self:_send( nil, event.emsg )
		self:dispatchEvent( self.ERROR, { emsg=event.emsg } )
		removeNetStream( self, event )

	end

end

function NetStream:_onData_handler( event )
	-- print("NetStream:_onData_handler", event.status )
	event = event or {}
	-- print( '>>', event.type, event.status, event.bytes )
	--==--

	local cb = function( e )
		-- print("=== Data Event ===\n\n")
		-- print( 'data re>> ', e.data, e.emsg )
		-- Utils.hexDump( e.data )
		self:_send( e.data, e.emsg )
		self:dispatchEvent( self.DATA, { data=e.data, emsg=event.emsg } )
	end
	self._sock:receive( '*a', cb  )
end



--====================================================================--
--== NetStream Facade
--====================================================================--


return {
	newStream = createNetStream
}



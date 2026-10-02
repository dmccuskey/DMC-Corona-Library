--====================================================================--
-- dmc_mockserver.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-mockserver
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : DMC Mock Server
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.0.0"



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
--== DMC Mock Server
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_mockserver = dmc_lib_data.dmc_mockserver or {}

local DMC_MOCKSERVER_DEFAULTS = {
	debug_active=false
}

local dmc_mockserver_data = Utils.extend( dmc_lib_data.dmc_mockserver, DMC_MOCKSERVER_DEFAULTS )
local Config = dmc_mockserver_data



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local urllib = require 'socket.url'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local sfmt = string.format
local tinsert = table.insert



--====================================================================--
--== Mock Server Class
--====================================================================--


local MockServer = newClass( ObjectBase, {name="DMC Mock Server"} )

MockServer.VERSION = VERSION

--== Class Constants

MockServer.REQUEST_DELAY = 500 -- milliseconds

MockServer.DOWNLOAD = 'download'
MockServer.REQUEST = 'request'

MockServer.NOT_FOUND = 404



--======================================================--
-- Start: Setup DMC Objects

-- __init__()
--
-- @param params table, optional
--   delay: number, ms before a mocked response, default REQUEST_DELAY
--   debug_on: boolean, print each request, default from the cfg
--
function MockServer:__init__( params )
	-- print( "MockServer:__init__" )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	if params.debug_on==nil then params.debug_on = Config.debug_active end

	--== Create Properties ==--

	self._network = _G.network
	self._request_delay = params.delay or self.REQUEST_DELAY
	self._debug_on = params.debug_on

	self._filter = nil -- table of filter functions, by request type
	self._actions = nil -- table of responses, by request type and method
	self._pending = nil -- table of timers, by request id

end

-- __initComplete__()
--
function MockServer:__initComplete__()
	-- print( "MockServer:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--

	self._actions = {}
	self._filter = {}
	self._pending = {}

	-- the network.* API, called with a dot like the module
	self.request = self:createCallback( self._request )
	self.download = self:createCallback( self._download )
	self.cancel = self:createCallback( self._cancel )

end

function MockServer:__undoInitComplete__()
	-- print( "MockServer:__undoInitComplete__" )

	for id in pairs( self._pending ) do
		self:_cancel( id )
	end

	--==--
	self:superCall( '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function MockServer.__getters:delay()
	return self._request_delay
end
function MockServer.__setters:delay( value )
	-- print( "MockServer.__setters:delay ", value )
	assert( type( value )=='number' and value>=0, "MockServer.delay: expected a number, 0 or more" )
	self._request_delay = value
end


--[[

self._actions = {
	request={
		GET={
			{ url='^/api/user', action={ 200, headers, func_or_string } }
		}
	},
	download={ ... }
}

--]]

-- respondWith()
-- add a response for a request type, HTTP method and URL path pattern
-- the first added pattern which matches the path is used
--
-- @param req_type string, MockServer.REQUEST or MockServer.DOWNLOAD
-- @param method string, eg 'GET'
-- @param url string, a Lua pattern matched against the URL's path
-- @param response table, { status, headers, func }; for a request,
--   func may be a string, the response body
--
function MockServer:respondWith( req_type, method, url, response )
	-- print( "MockServer:respondWith", req_type, method, url, response )
	assert( req_type==self.REQUEST or req_type==self.DOWNLOAD, "MockServer:respondWith: unknown request type "..tostring( req_type ) )
	assert( type( method )=='string', "MockServer:respondWith: expected a string for method" )
	assert( type( url )=='string', "MockServer:respondWith: expected a string for url" )
	assert( type( response )=='table', "MockServer:respondWith: expected a table for response" )

	local resp_hash = self._actions
	method = method:upper()

	-- check for request type, eg 'download'
	if not resp_hash[ req_type ] then resp_hash[ req_type ] = {} end
	resp_hash = resp_hash[ req_type ]

	-- check for http method, eg 'POST'
	if not resp_hash[ method ] then resp_hash[ method ] = {} end

	tinsert( resp_hash[ method ], { url=url, action=response } )
end

-- convenience function
--
function MockServer:requestRespondWith( method, url, response )
	-- print( "MockServer:requestRespondWith", method, url, response  )
	self:respondWith( self.REQUEST, method, url, response )
end
-- convenience function
--
function MockServer:downloadRespondWith( method, url, response )
	-- print( "MockServer:downloadRespondWith", method, url, response  )
	self:respondWith( self.DOWNLOAD, method, url, response )
end


-- addFilter()
-- set the filter for a request type: a function( url, method, params )
-- returning true for a request the mock answers; others go to the
-- real network. nil removes it: the mock answers every request
--
function MockServer:addFilter( req_type, req_filter )
	-- print( "MockServer:addFilter", req_type, req_filter  )
	assert( req_type==self.REQUEST or req_type==self.DOWNLOAD, "MockServer:addFilter: unknown request type "..tostring( req_type ) )
	self._filter[ req_type ] = req_filter
end

-- convenience function
--
function MockServer:addRequestFilter( req_filter )
	-- print( "MockServer:addRequestFilter", req_filter  )
	self:addFilter( self.REQUEST, req_filter )
end
-- convenience function
--
function MockServer:addDownloadFilter( req_filter )
	-- print( "MockServer:addDownloadFilter", req_filter  )
	self:addFilter( self.DOWNLOAD, req_filter )
end



--====================================================================--
--== Corona API Response Methods


-- _request()
-- like network.request( url, method, listener [, params] )
--
function MockServer:_request( url, method, callback, params )
	-- print( "MockServer:_request", url, method, callback, params )
	method = ( method or 'GET' ):upper()

	if not self:_mockHandlesRequestResponse( url, method, params ) then
		self:_debug( "passing on request", method, url )
		return self._network.request( url, method, callback, params )
	end

	return self:_schedule( function( id )
		return self:_doRequestResponse( id, url, method, callback, params )
	end )
end

-- _download()
-- like network.download( url, method, listener [, params], filename [, baseDirectory] )
--
function MockServer:_download( url, method, callback, params, filename, base_dir )
	-- print( "MockServer:_download", url, method, callback, params, filename, base_dir )
	method = ( method or 'GET' ):upper()

	-- params is optional, as in network.download()
	if type( params )=='string' then
		params, filename, base_dir = nil, params, filename
	end

	if not self:_mockHandlesDownloadResponse( url, method, params ) then
		self:_debug( "passing on download", method, url )
		return self._network.download( url, method, callback, params, filename, base_dir )
	end

	base_dir = base_dir or system.DocumentsDirectory

	return self:_schedule( function( id )
		return self:_doDownloadResponse( id, url, method, callback, params, filename, base_dir )
	end )
end

-- _cancel()
-- like network.cancel( requestId ); a mocked request is never answered
--
function MockServer:_cancel( id )
	-- print( "MockServer:_cancel", id )
	local t = self._pending[ id ]
	if t then
		self._pending[ id ] = nil
		timer.cancel( t )
		return true
	elseif type( id )=='table' and id.mock then
		-- ours, answered or cancelled already
		return false
	elseif id~=nil and self._network and self._network.cancel then
		return self._network.cancel( id )
	end
	return false
end



--====================================================================--
--== Private Methods


function MockServer:_debug( ... )
	if not self._debug_on then return end
	local args = { ... }
	for i = 1, #args do args[i] = tostring( args[i] ) end
	print( "MockServer: "..table.concat( args, " " ) )
end


-- _schedule()
-- answer after the delay; the request id is a table, a stand-in for
-- the one network.request() returns
--
function MockServer:_schedule( func )
	local id = { mock=self }
	self._pending[ id ] = timer.performWithDelay( self._request_delay, function()
		if not self._pending[ id ] then return end
		self._pending[ id ] = nil
		func( id )
	end )
	return id
end


-- _mockHandlesResponse()
-- test if we are to handle or pass on request
--
function MockServer:_mockHandlesResponse( req_type, url, method, params )
	-- print( "MockServer:_mockHandlesResponse", req_type, url, method, params  )

	local filter = self._filter[ req_type ]

	if not filter then
		return true
	else
		return filter( url, method, params )
	end
end

function MockServer:_mockHandlesRequestResponse( url, method, params )
	return self:_mockHandlesResponse( self.REQUEST, url, method, params )
end
function MockServer:_mockHandlesDownloadResponse( url, method, params )
	return self:_mockHandlesResponse( self.DOWNLOAD, url, method, params )
end


-- _findAction()
-- the response for the first pattern which matches the URL's path,
-- or nil
--
function MockServer:_findAction( req_type, url, method )
	-- print( "MockServer:_findAction", req_type, url, method  )

	local url_parts = type( url )=='string' and urllib.parse( url )
	local resp_hash = self._actions[ req_type ]
	local resp_list = resp_hash and resp_hash[ method ]

	if not url_parts or not resp_list then return nil end

	local path = url_parts.path or '/'

	for _, v in ipairs( resp_list ) do
		if string.match( path, v.url ) then
			return v.action
		end
	end

	return nil
end

function MockServer:_findRequestAction( url, method )
	return self:_findAction( self.REQUEST, url, method )
end
function MockServer:_findDownloadAction( url, method )
	return self:_findAction( self.DOWNLOAD, url, method )
end


function MockServer:_notFound( event, url, method )
	print( sfmt( "MockServer: no response for %s '%s', answering %d", tostring( method ), tostring( url ), self.NOT_FOUND ) )
	event.isError = false
	event.status = self.NOT_FOUND
end


function MockServer:_doRequestResponse( id, url, method, callback, params )
	-- print( "MockServer:_doRequestResponse", url, method, callback, params )

	local action, data, event

	--== Create HTTP response with Corona Event

	event = {
		name='networkRequest',
		phase='ended',
		isError=false,

		responseType='text',
		responseHeaders={},
		url=url,
		bytesTransferred=0,

		status=nil, -- 200, etc
		response='',

		requestId=id,
	}

	--== Check our setup

	action = self:_findRequestAction( url, method )

	if not action then
		self:_notFound( event, url, method )

	else
		local resp_status, resp_headers, resp_func = action[1], action[2], action[3]

		if type( resp_func )=='function' then
			data = resp_func( url, method, params, resp_status, resp_headers )
		else
			data = resp_func
		end
		self:_debug( "request", method, url, "answering", resp_status )

		event.responseHeaders = resp_headers or {}

		if data==nil then
			-- as from the network, when the request fails
			event.isError = true
			event.status = -1
			event.response = nil
		else
			data = tostring( data )
			event.status = resp_status
			event.bytesTransferred = #data
			event.response = data
		end
	end

	if callback then callback( event ) end
end


function MockServer:_doDownloadResponse( id, url, method, callback, params, filename, base_dir )
	-- print( "MockServer:_doDownloadResponse", url, method, callback, params, filename, base_dir )

	local action, success, event

	--== Create HTTP response with Corona Event

	event = {
		name='networkRequest',
		phase='ended',
		isError=false,

		responseHeaders={},
		url=url,
		bytesTransferred=0,

		status=nil, -- 200, etc
		response={
			filename=filename,
			baseDirectory=base_dir,
		},

		requestId=id,
	}

	--== Check our setup

	action = self:_findDownloadAction( url, method )

	if not action then
		self:_notFound( event, url, method )

	else
		local resp_status, resp_headers, resp_func = action[1], action[2], action[3]

		success = resp_func( url, method, params, filename, base_dir, resp_status, resp_headers )
		self:_debug( "download", method, url, "answering", resp_status )

		event.responseHeaders = resp_headers or {}

		if not success then
			-- as from the network, when the download fails
			event.isError = true
			event.status = -1
		else
			event.status = resp_status
		end
	end

	if callback then callback( event ) end
end




return MockServer

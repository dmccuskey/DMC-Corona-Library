--====================================================================--
-- dmc_corona/dmc_websockets/handshake.lua
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
--== DMC Corona Library : DMC WebSockets Handshake
--====================================================================--


--[[

WebSocket support adapted from:
* Lumen (http://github.com/xopxe/Lumen)
* lua-websocket (http://lipp.github.io/lua-websockets/)
* lua-resty-websocket (https://github.com/openresty/lua-resty-websocket)

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.0"



--====================================================================--
--== Imports


local mime = require 'mime'
local Patch = require 'lib.dmc_lua.lua_patch'
local SHA1 = require 'lib.sha1'



--====================================================================--
--== Setup, Constants


Patch.addPatch( 'string-format' )

local assert = assert
local ipairs = ipairs
local mbase64_encode = mime.b64
local mrandom = math.random
local schar = string.char
local sgmatch = string.gmatch
local slower = string.lower
local smatch = string.match
local tconcat = table.concat
local tinsert = table.insert
local type = type

local HANDSHAKE_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'

local LOCAL_DEBUG = false



--====================================================================--
--== Support Functions


local function generateKey( params )
	local key = schar(
		mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff),
		mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff),
		mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff),
		mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff), mrandom(0,0xff)
	)
	return mbase64_encode( key )
end


local function createHttpRequest( params )
	-- print( "handshake:createHttpRequest" )
	params = params or {}

	local host, port, path = params.host, params.port, params.path
	local protos = params.protocols

	local proto_header, key
	local req_t

	if type(protos) == 'string' then
		proto_header = protos
	elseif type(protos) == 'table' then
		proto_header = tconcat( protos, "," )
	end

	key = generateKey()

	-- create http header
	req_t = {
		"GET %s HTTP/1.1" % path,
		"Host: %s:%s" % { host, port },
		"Upgrade: websocket",
		"Connection: Upgrade",
		"Sec-WebSocket-Version: 13",
		"Sec-WebSocket-Key: %s" % key,
	}
	if proto_header then
		tinsert( req_t, "Sec-WebSocket-Protocol: %s" % proto_header )
	end
	if params.origin then
		tinsert( req_t, "Origin: %s" % params.origin )
	end
	if params.user_agent then
		tinsert( req_t, "User-Agent: %s" % params.user_agent )
	end
	tinsert( req_t, "" )
	tinsert( req_t, "" )

	if LOCAL_DEBUG then
		print( "Request Header" )
		print( tconcat( req_t, "\r\n" ) )
	end
	return tconcat( req_t, "\r\n" ), key
end


local function buildServerKey( key )
	-- print( "handshake:buildServerKey" )
	assert( type(key)=='string', "expected string for key" )
	--==--
	local srvr_key = key..HANDSHAKE_GUID
	local key_sha = SHA1.sha1_binary( srvr_key )
	return mbase64_encode( key_sha )
end

local function createHttpResponseHash( response )
	-- print( "handshake:createHttpResponseHash" )
	assert( type(response)=='table', "expected table of response lines" )
	--==--
	local resp_hash = {}
	for i,v in ipairs( response ) do
		-- whitespace around the value is optional
		local key, value = smatch( v, '^([^:%s]+):%s*(.-)%s*$' )
		if key and value then
			key = slower( key )
			if key == 'sec-websocket-accept' or key == 'sec-websocket-protocol' then
				resp_hash[ key ] = value -- case-sensitive values
			else
				resp_hash[ key ] = slower( value )
			end
		end
	end
	return resp_hash
end

-- true if list contains value
--
local function hasTokenIn( list, value )
	for i=1,#list do
		if list[i] == value then return true end
	end
	return false
end

-- true if comma-separated header value contains token
--
local function hasToken( value, token )
	for item in sgmatch( value or '', '[^,]+' ) do
		if smatch( item, '^%s*(.-)%s*$' ) == token then return true end
	end
	return false
end

-- @param response array of lines from http response string
-- @param key the Sec-WebSocket-Key sent in the request
-- @param protocols string or table of subprotocols requested, optional
--
--[[
-- requires:
-- response code 101
-- upgrade: websocket
-- connection: upgrade (may be one of several tokens)
-- sec-websocket-accept: matching our key
-- sec-websocket-protocol: absent, or one we requested
-- sec-websocket-extensions: absent, we don't offer any
--]]
local function checkHttpResponse( response, key, protocols )
	-- print( "handshake:checkHttpResponse" )
	assert( type(response)=='table', "expected table of response lines" )
	assert( #response>0, "expected table of response lines" )
	assert( type(key)=='string', "expected handshake key" )
	--==--

	-- check for http result code - 101
	if smatch( response[1], '^HTTP/1.1%s+101' ) == nil then
		return false
	end

	local resp_hash = createHttpResponseHash( response )
	local srvr_key = buildServerKey( key )

	if resp_hash.upgrade ~= 'websocket' then
		return false
	elseif not hasToken( resp_hash.connection, 'upgrade' ) then
		return false
	elseif resp_hash['sec-websocket-accept'] ~= srvr_key then
		return false
	elseif resp_hash['sec-websocket-extensions'] then
		return false
	end

	local protocol = resp_hash['sec-websocket-protocol']
	if protocol then
		if type( protocols ) == 'string' then protocols = { protocols } end
		if type( protocols ) ~= 'table' or not hasTokenIn( protocols, protocol ) then
			return false
		end
	end

	return true
end



--====================================================================--
--== Module Facade
--====================================================================--


return {
	createRequest = createHttpRequest,
	checkResponse = checkHttpResponse,

	-- for unit testing
	_buildServerKey = buildServerKey,
	_createHttpResponseHash = createHttpResponseHash
}

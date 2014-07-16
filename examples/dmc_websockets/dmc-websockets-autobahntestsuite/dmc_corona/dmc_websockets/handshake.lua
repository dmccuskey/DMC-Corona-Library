--====================================================================--
-- handshake.lua (part of dmc_websockets)
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
-- DMC Corona Library : WebSocket Handshake
--====================================================================--


--[[

WebSocket support adapted from:
* Lumen (http://github.com/xopxe/Lumen)
* lua-websocket (http://lipp.github.io/lua-websockets/)
* lua-resty-websocket (https://github.com/openresty/lua-resty-websocket)

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.1.2"


--====================================================================--
-- Imports

local mime = require 'mime'
local Patch = require( 'lua_patch' )( 'string-format' )
local SHA1 = require 'libs.sha1'


--====================================================================--
-- Setup, Constants

local mbase64_encode = mime.b64
local mrandom = math.random
local schar = string.char
local tconcat = table.concat
local tinsert = table.insert

local HANDSHAKE_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'

local LOCAL_DEBUG = false


--====================================================================--
-- Support Functions

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

	if type( protos ) == "string" then
		proto_header = protos
	elseif type( protos ) == "table" then
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
		local key, value = string.match( v, '^([%w-%p]+): (.+)$' )
		if key and value then
			key = string.lower( key )
			if key == 'sec-websocket-accept' then
				resp_hash[ key ] = value
			else
				resp_hash[ key ] = string.lower( value )
			end
		end
	end
	return resp_hash
end

-- @param response array of lines from http response string
--
--[[
-- requires:
-- response code 101
-- upgrade: websocket
-- connection: upgrade
-- sec=websocket-accept:
--]]
local function checkHttpResponse( response, key )
	-- print( "handshake:checkHttpResponse" )
	assert( type(response)=='table', "expected table of response lines" )
	assert( #response>0, "expected table of response lines" )
	assert( type(key)=='string', "expected handshake key" )
	--==--

	-- check for http result code - 101
	if string.match( response[1], '^HTTP/1.1%s+101' ) == nil then
		return false
	end

	local resp_hash = createHttpResponseHash( response )
	local srvr_key = buildServerKey( key )

	if resp_hash.upgrade ~= 'websocket' then
		return false
	elseif resp_hash.connection ~= 'upgrade' then
		return false
	elseif resp_hash['sec-websocket-accept'] ~= srvr_key then
		return false
	end

	return true
end


return {
	createRequest = createHttpRequest,
	checkResponse = checkHttpResponse,

	-- for unit testing
	_buildServerKey = buildServerKey,
	_createHttpResponseHash = createHttpResponseHash
}

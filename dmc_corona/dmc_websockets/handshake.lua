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

local VERSION = "1.0.0"


--====================================================================--
-- Imports

local mime = require 'mime'
local patch = require 'dmc_patch'


--====================================================================--
-- Setup, Constants

local mbase64_encode = mime.b64
local mrandom = math.random
local schar = string.char
local tconcat = table.concat

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

	local proto_header --, sock_opts
	local bytes, key
	local req_t, req

	if not protos then
		proto_header = ""

	elseif type( protos ) == "table" then
		proto_header = tconcat( protos, "," )

	else
		proto_header = protos
	end

	key = generateKey()

	-- create http header
	req_t = {
		"GET %s HTTP/1.1\r\n" % path,
		"Upgrade: websocket\r\n",
		"Host: %s:%s\r\n" % { host, port },
		"Sec-WebSocket-Key: %s\r\n" % key ,
		"Sec-WebSocket-Protocol: %s\r\n" % proto_header,
		"Sec-WebSocket-Version: 13\r\n",
		"Connection: Upgrade\r\n",
		"\r\n"
	}

	if LOCAL_DEBUG then
		print( "Request Header" )
		print( tconcat( req_t, "" ) )
	end
	return tconcat( req_t, "" )
end


-- @param response array of lines from http response string
--
local function checkHttpResponse( response )
	-- print( "handshake:checkHttpResponse" )
	-- TODO: check response
	-- for i,v in ipairs( response ) do
	-- 	print(i,v)
	-- end
	return true
end


return {
	createRequest = createHttpRequest,
	checkResponse = checkHttpResponse
}

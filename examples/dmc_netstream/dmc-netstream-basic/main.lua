--====================================================================--
-- WAMP Basic Publish/Subscribe
--
-- Basic Pub/Sub test for the WAMP library
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--


print( '\n\n##############################################\n\n' )


--====================================================================--
-- Imports

local Objects = require 'dmc_corona.dmc_objects' -- just for import

local NetStream = require 'dmc_netstream'


--====================================================================--
-- Setup, Constants

--== Fill in the IP Address and Port for the WAMP Server
--
local host, port = 'http://192.168.3.92', 4411

local netstream


--====================================================================--
-- Support Functions

-- self._url = params.url
-- self._method = params.method or 'GET'
-- self._req_data = params.data

-- self._resp_data = nil


local params, headers = {}, {}
params.headers = headers

headers["Cache-Control"] = "no-cache"

-- local data = self._req_data
-- if data then
-- 	if type(data)=='table' then
-- 		data = Utils.createQuery( self._req_data )
-- 	end
-- 	params.body = data

-- 	headers["Content-Type"] = "application/x-www-form-urlencoded"
-- 	headers["Content-Length"] = string.len( params.body )
-- 	self._method = 'POST'
-- end

-- params = {
-- 	headers= headers, -- { },
-- 	body = body, -- "",
-- 	bodyType = nil, -- 'text', --'binary'
-- 	progress = nil, -- 'upload', 'download'
-- 	response = nil, -- { filename, basedir }, or will return as string
-- 	timeout = 30, -- timeout
-- 	handleRedirects = true, -- false
-- }

local cb = function( event )
	local data, emsg = event.data, event.emsg
	print("in callback", data, emsg )

end
NetStream.stream( { url="http://192.168.3.92:4411", method='GET', listener=cb, params=params } )

--====================================================================--
-- Main
--====================================================================--

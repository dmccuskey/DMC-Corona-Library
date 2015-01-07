--====================================================================--
-- Netstream Basic
--
-- basic streaming example
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


local NetStream = require 'dmc_corona.dmc_netstream'



--====================================================================--
--== Setup, Constants


-- Fill in information for the HTTP Server
--
local HOST, PORT = 'http://192.168.3.92', 4411



--====================================================================--
--== Main
--====================================================================--


local params, headers = {}, {}
params.headers = headers

headers['Cache-Control'] = 'no-cache'

local event_handler = function( event )
	local stream, etype = event.target, event.type
	local data, emsg = event.data, event.emsg
	-- print("\n\nIn netstream handler", etype, data, emsg )

	if etype == stream.CONNECTING then
		print( "NetStream: CONNECTING" )

	elseif etype == stream.CONNECTED then
		print( "NetStream: CONNECTED" )

	elseif etype == stream.DATA then
		-- print( "NetStream: DATA", data )

	elseif etype == stream.DISCONNECTED then
		print( "NetStream: DISCONNECTED" )

	elseif etype == stream.ERROR then
		print( "NetStream: ERROR" )

	end

end

local data_func = function( event )
	local data, emsg = event.data, event.emsg
	print("\n\nIn data callback", data, emsg )
end

local netstream = NetStream.newStream{
	url=HOST..':'..PORT,
	method='GET',
	listener=data_func,
	params=params
}

netstream:addEventListener( netstream.EVENT, event_handler )

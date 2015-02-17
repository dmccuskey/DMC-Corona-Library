--====================================================================--
-- DMC WebSockets Pusher
--
-- Communicate with Pusher.com server
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014-2015 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


local WebSockets = require 'dmc_corona.dmc_websockets'
local SSLParams = require 'dmc_corona.dmc_sockets.ssl_params'
-- local Utils = require( "dmc_corona.dmc_utils" )



--====================================================================--
--== Setup, Constants


local ws



--====================================================================--
--== Main Functions


local function webSocketsEvent_handler( event )
	print( "webSocketsEvent_handler", event.type )
	local evt_type = event.type

	if evt_type == ws.ONOPEN then
		print( 'Received event: ONOPEN' )

	elseif evt_type == ws.ONMESSAGE then
		local msg = event.message

		print( "Received event: ONMESSAGE" )
		print( "message: '" .. tostring( msg.data ) .. "'\n\n" )

	elseif evt_type == ws.ONCLOSE then
		print( "Received event: ONCLOSE" )
		print( 'code:reason', event.code, event.reason )

	elseif evt_type == ws.ONERROR then
		print( "Received event: ONERROR" )

	end
end


ws = WebSockets{
	-- non-secure
	-- uri='ws://ws.pusherapp.com:80/app/a6fc0e5ee5adc489d1ac?client=lua&version=1.0&protocol=7',
	-- secure (SSL/TLS)
	uri='wss://ws.pusherapp.com:443/app/a6fc0e5ee5adc489d1ac?client=lua&version=1.0&protocol=7',
	-- port can be here, or in URI
	-- port=443, -- 80/443
	ssl_params = {protocol=SSLParams.TLS_V1},
	protocols='7'
}
ws:addEventListener( ws.EVENT, webSocketsEvent_handler )

--====================================================================--
-- Websockets Echo
--
-- Communicate with Websockets echo server
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--


print( '\n\n##############################################\n\n' )


--====================================================================--
-- Imports

local WebSockets = require 'dmc_corona.dmc_websockets'
-- local Utils = require( "dmc_corona.dmc_utils" )


--====================================================================--
-- Setup, Constants

local ws


--====================================================================--
-- Support Functions

local function sendMessages()

	local num_msgs = 5
	local count = 0

	print("=== Sending " .. tostring( num_msgs ) .. " messages ===\n")

	local f = function()

		count = count + 1
		local str = "Current app time: " .. tostring( system.getTimer() )
		print( "Sending message (" .. tostring( count ) .. "): '" .. str .. "'")

		-- ws:_sendPing()
		ws:send( str )

		if count == num_msgs then
			timer.performWithDelay( 1500, function() print( "Closing WebSocket connection" ); ws:close() end )
		end

	end

	timer.performWithDelay( 1000, f, num_msgs )

end


--====================================================================--
-- Main Functions

local function webSocketsEvent_handler( event )
	-- print( "webSocketsEvent_handler", event.type )
	local evt_type = event.type

	if evt_type == ws.ONOPEN then
		print( 'Received event: ONOPEN' )
		sendMessages()

	elseif evt_type == ws.ONMESSAGE then
		local msg = event.message

		print( "Received event: ONMESSAGE" )
		print( "echoed message: '" .. tostring( msg.data ) .. "'\n\n" )

	elseif evt_type == ws.ONCLOSE then
		print( "Received event: ONCLOSE" )
		print( 'code:reason', event.code, event.reason )

	elseif evt_type == ws.ONERROR then
		print( "Received event: ONERROR" )
		-- Utils.print( event )

	end
end

ws = WebSockets{
	uri='ws://echo.websocket.org'
}
ws:addEventListener( ws.EVENT, webSocketsEvent_handler )

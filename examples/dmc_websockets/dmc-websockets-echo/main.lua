print( '\n\n##############################################\n\n' )


--====================================================================--
-- Imports
--====================================================================--

-- local Utils = require( "dmc_library.dmc_utils" )
local WebSockets = require 'dmc_library.dmc_websockets'


--====================================================================--
-- Setup, Constants
--====================================================================--

local ws, p


--====================================================================--
-- Support Functions
--====================================================================--


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
--====================================================================--

local function webSocketsEvent_handler( event )

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

	elseif evt_type == ws.ONERROR then
		print( "Received event: ONERROR" )
		-- Utils.print( event )

	end
end

p = {
	uri='ws://echo.websocket.org'
}
ws = WebSockets:new( p )
ws:addEventListener( ws.EVENT, webSocketsEvent_handler )

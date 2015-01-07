--====================================================================--
--== DMC Net Stream test server
--====================================================================--


--[[

very basic server to test dmc_netstream module

--]]

-- flag: split up header
local SIMPLE = true

local socket = require 'socket'

print( "Bind: to port" )
local server = assert( socket.bind('*', 4411) )

print( "Wait: for connection" )
local client = server:accept()

print( "Connection: from client" )
socket.sleep( 2 )

local http_header = "HTTP/1.0 200 OK\r\n"
http_header = http_header .. "Date: Mon 02 Mar 1998 10:20:00 GMT\r\n\r\n"

if SIMPLE then
	print( "Send: HTTP header" )
	client:send( http_header )

else
	print( "Send: HTTP complex header" )

	-- add some data to header string
	http_header = http_header .. "one two three four five six seven eight"

	client:send( string.sub( http_header, 1, 10 ) )

	socket.sleep( 1 )

	client:send(  string.sub( http_header, 11 ) )

end

while 1 do
	socket.sleep( 2 )
	local data = 'data@'..tostring( os.time() )
	print( "Send: data to client '" .. data .. "'" )
	client:send( data )
end

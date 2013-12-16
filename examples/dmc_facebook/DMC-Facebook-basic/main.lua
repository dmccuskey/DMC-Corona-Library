--====================================================================--
-- DMC Facebook Basic Example
--
--====================================================================--

print("---------------------------------------------------")


--===================================================================--
-- Imports
--===================================================================--

local Facebook = require( "dmc_facebook" )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- USE *YOUR* FACEBOOK APPLICATION INFO FOR THESE SETTINGS !!
--
local APP_ID = '236229049738744'
local APP_URL = 'http://m.davidmccuskey.com'


--===================================================================--
-- Main
--===================================================================--

local facebook_handler = function( event )

	if event.type == Facebook.LOGIN then
		print( "--== We are now logged in" )
		print( "\n" )

		-- get some data
		Facebook:request( 'me' )

	elseif event.type == Facebook.REQUEST then
		print( "--== Request() data response" )

		-- output results
		local data = event.data
		print( "Name: ", data.name, data.last_name )
		print( "Username: ", data.username )
		print( "User URL: ", data.link )
		print( "\n" )

		-- now logout
		Facebook:logout()

	elseif event.type == Facebook.LOGOUT then
		print( "--== We are now logged out" )
	end

end

-- initialize facebook plugin
Facebook:init( APP_ID, APP_URL )
Facebook:addEventListener( Facebook.EVENT, facebook_handler )

-- login to facebook, 'basic_info' is default perms
Facebook:login()




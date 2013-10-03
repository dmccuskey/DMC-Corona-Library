--====================================================================--
-- DMC Facebook Basic Example
--
--====================================================================--

print("---------------------------------------------------")


--===================================================================--
-- Imports
--===================================================================--

local widget = require( "widget" )
local Utils = require( 'dmc_utils' )

local Facebook = require( "dmc_facebook" )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- USE *YOUR* FACEBOOK APPLICATION INFO FOR THESE SETTINGS !!
--
local APP_ID = '236229049738744'
local APP_URL = 'http://m.davidmccuskey.com'
-- local APP_TOKEN_URL = 'http://m.davidmccuskey.com/app_token.php'


--===================================================================--
-- Main
--===================================================================--

local btn_login, btn_logout, btn_read, btn_post

-- showAlert
-- helper for showing our alerts
--
local function showAlert( message )
	native.showAlert( "DMC Facebook Plugin", message, { "OK" }, onComplete )
end

-- toggleLoginLogoutButtons
-- show button Login or Logout depending on state of Facebook Login
--
local function toggleLoginLogoutButtons()

	if Facebook.has_login then
		btn_login.isVisible = false
		btn_logout.isVisible = true
	else
		btn_login.isVisible = true
		btn_logout.isVisible = false
	end

end

-- invokeFacebookCommand
-- run a command on Facebook
-- we made this so facebookHandler() below is a little easier to read
--
local function invokeFacebookCommand( cmd )

	if cmd == 'post_msg' then
		local msg = "Test message post @ " .. tostring( os.time() )
		Facebook:postMessage( msg )

	elseif cmd == 'post_link' then
		local link = 'http://m.davidmccuskey.com/'
		local params = {
			picture='http://developer.coronalabs.com/demo/Corona90x90.png',
			name='Mobile homepage for DMC',
			caption='The Link Caption',
			description='This is the description for the link post.',
			actions={ { name = "Learn More", link = "http://docs.davidmccuskey.com" } }
		}
		Facebook:postLink( link, params )
	end

end

-- facebookHandler
-- handle data return from Facebook calls
--
local function facebookHandler( event )
	-- print( 'Main: facebookHandler', event.type )
	-- Utils.print( event )

	local data = event.data

	if event.type == Facebook.LOGIN then
		if event.is_error then
			showAlert( "Error with login: " .. data.message )
		else
			local str = "Successful Login: "
			if event.had_login and not event.had_permissions then
				str = str .. "existing auth only"
			elseif not event.had_login and event.had_permissions then
				str = str .. "existing perms only"
			elseif event.had_login and event.had_permissions then
				str = str .. "existing auth and perms"
			else
				str = str .. "neither existing auth nor perms"
			end
			showAlert( str )
		end
		toggleLoginLogoutButtons()


	elseif event.type == Facebook.LOGOUT then
		toggleLoginLogoutButtons()


	elseif event.type == Facebook.ACCESS_TOKEN then
		print( "Access token has changed" )


	elseif event.type == Facebook.POST_MESSAGE then
		if event.is_error then
			showAlert( "Error posting message: " .. data.message )
		else
			showAlert( "Message successfully posted" )
		end


	elseif event.type == Facebook.GET_PERMISSIONS then
		if event.is_error then
			showAlert( "Error getting permissions: " .. data.message )
		else
			local params = event.params
			local has_command = (params and params.next_command)
			local has_perms = (data.publish_stream == 1)

			-- see if we're just checking perms for another operation
			if not has_command then
				showAlert( "Get Permissions successful" )
			else
				if has_perms then
					invokeFacebookCommand( params.next_command )
				else
					showAlert( "Get Permissions successful, tho perms not good for call" )
				end
			end
		end


	elseif event.type == Facebook.POST_LINK then
		if event.is_error then
			showAlert( "Error posting link: " .. data.message )
		else
			showAlert( "Link successfully posted" )
		end


	elseif event.type == Facebook.REQUEST then

		if event.path == 'me' then
			if event.is_error then
				showAlert( "Error in request: " .. data.message )
			else
				print( "-- Request Data --" )
				Utils.print( data )
				showAlert( "Data request successful" )
			end

		end

	end
end

-- buttonHandler
-- handle button clicks
--
local function buttonHandler( event )
	-- print( 'Main: buttonHandler', event.type )
	local button = event.target

	if button.id == 'login' then
		Facebook:login( { 'publish_stream' } )

	elseif button.id == 'logout' then
		Facebook:logout()

	elseif button.id == 'read' then
		if Facebook.has_login then
			Facebook:request( 'me' )
		else
			showAlert( "You need to first Login" )
		end

	elseif button.id == 'post_msg' then
		if Facebook.has_login then
			Facebook:getPermissions( { next_command='post_msg' } )
		else
			showAlert( "You need to first Login" )
		end

	elseif button.id == 'post_link' then
		if Facebook.has_login then
			Facebook:getPermissions( { next_command='post_link' } )
		else
			showAlert( "You need to first Login" )
		end

	end

	return true
end

-- setupUI
-- put UI buttons on stage
--
local function setupUI()

	local params = {
		left=60, top=0,
		width=200, height=50,
		label = '',
		onRelease = buttonHandler
	}

	-- login button
	params.label = 'login'
	params.id = 'login'
	params.top = 400
	btn_login = widget.newButton( params )

	-- logout button
	params.label = 'logout'
	params.id = 'logout'
	btn_logout = widget.newButton( params )

	-- read button
	params.label = 'read data'
	params.id = 'read'
	params.top = 125
	btn_read = widget.newButton( params )

	-- post message button
	params.label = 'post message'
	params.id = 'post_msg'
	params.top = 200
	btn_post = widget.newButton( params )

	-- post link button
	params.label = 'post link'
	params.id = 'post_link'
	params.top = 275
	btn_post = widget.newButton( params )

	toggleLoginLogoutButtons()

end


-- main()
-- control app bootstrap
--
local main = function()

	local fb_options = {
		view_type=Facebook.MOBILE_VIEW,
		view_params={
			x=10, y=10, w=display.contentWidth-20, h=display.contentHeight-20
		},
		app_token_url = APP_TOKEN_URL
	}

	Facebook:init( APP_ID, APP_URL, fb_options )
	Facebook:addEventListener( Facebook.EVENT, facebookHandler )

	setupUI()

end


-- let's get this party started !
main()




--====================================================================--
-- DMC Facebook Basic Example
--
--====================================================================--

print("---------------------------------------------------")


-- TODO: put this setup in dmc library config
_G.__dmc_library = {
	dmc_library = { location='' }
}

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
local APP_TOKEN_URL = 'http://m.davidmccuskey.com/app_token.php'


--===================================================================--
-- Main
--===================================================================--

local btn_login, btn_logout, btn_read, btn_post

local function showAlert( message )
	native.showAlert( "DMC Facebook Plugin", message, { "OK" }, onComplete )
end

local function toggleLoginLogoutButtons()

	if Facebook.has_login then
		btn_login.isVisible = false
		btn_logout.isVisible = true

	else
		btn_login.isVisible = true
		btn_logout.isVisible = false

	end

end

local function facebookHandler( event )
	-- print( 'Main: facebookHandler', event.type )
	-- Utils.print( event )

	local data = event.data

	if event.type == Facebook.LOGIN then
		toggleLoginLogoutButtons()


	elseif event.type == Facebook.LOGOUT then
		toggleLoginLogoutButtons()


	elseif event.type == Facebook.ACCESS_TOKEN then
		showAlert( "Access token has changed" )


	elseif event.type == Facebook.POST_MESSAGE then
		if event.isError then
			showAlert( "Error posting message: " .. data.message )
		else
			showAlert( "Message successfully posted" )
		end


	elseif event.type == Facebook.POST_LINK then
		if event.isError then
			showAlert( "Error posting link: " .. data.message )
		else
			showAlert( "Link successfully posted" )
		end


	elseif event.type == Facebook.REQUEST then

		if event.path == 'me' then
			if event.isError then
				showAlert( "Error in request: " .. data.message )
			else
				Utils.print( data )
				showAlert( "Data request successful" )
			end

		end

	end
end

local function buttonHandler( event )
	-- print( 'Main: buttonHandler', event.type )
	local button = event.target

	if button.id == 'login' then
		Facebook:login( { 'publish_stream' }, fb_options )

	elseif button.id == 'logout' then
		Facebook:logout()

	elseif button.id == 'read' then
		Facebook:request( 'me', 'GET', params )

	elseif button.id == 'post_msg' then
		local msg = "Test message post @ " .. tostring( os.time() )
		Facebook:postMessage( msg )

	elseif button.id == 'post_link' then
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

	return true
end

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




--====================================================================--
-- dmc_facebook.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_facebook.lua
--====================================================================--

--[[

Copyright (C) 2013 David McCuskey. All Rights Reserved.

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


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"


--====================================================================--
-- DMC Library Setup
--====================================================================--

-- TODO: add reading of dmc library config

local Utils = {} -- make copying from Utils easier

local dmc_lib_data, dmc_lib_info, dmc_lib_location

dmc_lib_data = _G.__dmc_library or {}
dmc_lib_info = dmc_lib_data.dmc_library or {}

if dmc_lib_info.location ~= nil and dmc_lib_info.location ~= ''  then
	dmc_lib_location = dmc_lib_info.location .. '.'
else
	dmc_lib_location = ''
end


--====================================================================--
-- Imports
--====================================================================--

local UrlLib = require( 'socket.url' )
local json = require( 'json' )

local Objects = require( dmc_lib_location .. 'dmc_objects' )
-- local States = require( dmc_lib_location .. 'dmc_states' )

-- only needed for debugging
Utils = require( dmc_lib_location .. 'dmc_utils' )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase

local Facebook_Singleton -- ref to our singleton

--====================================================================--
-- Support Methods
--====================================================================--

--[[
	the functions url_encode() and url_decode() are borrowed from:
	http://lua-users.org/wiki/StringRecipes
--]]
function url_encode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w %-%_%.%~])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
	end
	return str
end

function url_decode(str)
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)",
		function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end


-- parse_query()
-- splits an HTTP query string (eg, 'one=1&two=2' ) into its components
-- returns a table with the key/value pairs
--
function parse_query(str)
	local t = {}
	if str ~= nil then
		for k, v in string.gmatch( str, "([^=&]+)=([^=&]+)") do
			t[k] = v
		end
	end
	return t
end

function create_query( tbl )
	local str = ''
	for k,v in pairs( tbl ) do
		if str ~= '' then str = str .. '&' end
		str = str .. tostring( k ) .. '=' .. url_encode( tostring(v) )
	end
	return str
end


--====================================================================--
-- Facebook Object
--====================================================================--

local Facebook = inheritsFrom( CoronaBase )

--== General Constants ==--

Facebook.BASIC_PERMS = 'basic_info' -- Facebook basic permissions string

Facebook.MOBILE_VIEW = 'mobile_web_view'
Facebook.DESKTOP_VIEW = 'desktop_web_view'
Facebook.VIEW_PARAMS = { x=0, y=0, w=display.contentWidth, h=display.contentHeight }


Facebook.GRAPH_URL = 'https://graph.facebook.com'

Facebook.AUTH_URLS = {
	desktop_web_view='https://www.facebook.com/dialog/oauth',
	mobile_web_view='https://m.facebook.com/dialog/oauth'
}
Facebook.LOGIN_URLS = {
	desktop_web_view='https://www.facebook.com/login.php',
	mobile_web_view='https://m.facebook.com/login.php'
}
Facebook.LOGOUT_URLS = {
	desktop_web_view='https://www.facebook.com/logout.php',
	mobile_web_view='https://m.facebook.com/logout.php'
}

-- list of errors which we can throw
Facebook.DMC_ERROR_TYPE = 'dmc_facebook'
Facebook.DMC_ERRORS = {
	no_login={
		code=5,
		message='No Valid Login Available',
	}
}

--== Event Constants ==--

Facebook.EVENT = 'dmc_facebook_plugin_event'

Facebook.LOGIN = 'login_query'
Facebook.REQUEST = 'request_query'
Facebook.GET_PERMISSIONS = 'get_permissions_query'
Facebook.REQUEST_PERMISSIONS = 'request_permissions_query'
Facebook.REMOVE_PERMISSIONS = 'remove_permissions_query'
Facebook.POST_MESSAGE = 'post_message_query'
Facebook.POST_LINK = 'post_link_query'
Facebook.LOGOUT = 'logout_query'

Facebook.POST_MESSAGE_PATH = 'me/feed'

Facebook.ACCESS_TOKEN = 'acces_token_changed'


--== Start: Setup DMC Objects

function Facebook:_init( params )
	--print( "Facebook:_init" )
	self:superCall( "_init" )
	--==--

	--== Create Properties ==--

	self._params = params

	self._view_type = ''  -- the type of login view to request
	self._view_params = nil  -- the parameters for the web view

	self._app_id = nil  -- the ID of the Facebook app, string
	self._app_url = nil  -- the URL for the Facebook app, string
	self._app_token_url = nil  -- the URL to get app token

	self._app_url_parts = nil -- table

	self._is_logged_in = nil  -- the access token handed back from Facebook API

	-- the access token handed back from Facebook API
	-- this can be written internally via self._access_token
	-- or read EXTERNALLY via self.access_token
	self._token = nil

	--== Display Groups ==--

	--== Object References ==--

	self._webview = nil  -- the webview created to display web login

end

--== END: Setup DMC Objects



--== Public Methods / API ==--



function Facebook.__getters:has_login()
	-- print( "Facebook.__getters:has_login" )
	return ( self._token ~= nil )
end

function Facebook.__getters:access_token()
	-- print( "Facebook.__getters:access_token" )
	return self._token
end


function Facebook:init( app_id, app_url, params )
	-- print( "Facebook:init", app_id, app_url )

	params = params or {}
	if params.view_type == nil then params.view_type = Facebook.MOBILE_VIEW end
	if params.view_params == nil then params.view_params = Facebook.VIEW_PARAMS end

	self._view_type = params.view_type
	self._view_params = params.view_params

	self._app_id = app_id
	self._app_url = app_url
	self._app_token_url = params.app_token_url

	self._app_url_parts =  UrlLib.parse( self._app_url )

end


--[[
login()
login to facebook api service

@param permissions: list of permission strings to request for user
@param params: table with additional login parameters

https://developers.facebook.com/docs/facebook-login/login-flow-for-web-no-jssdk/
--]]
function Facebook:login( permissions, params )
	-- print( "Facebook:login" )

	params = params or {}

	-- make sure to set basic permissions, according to Facebook spec
	if permissions[1] ~= Facebook.BASIC_PERMS then
		-- print( "adding basic permissions" )
		table.insert( permissions, 1, Facebook.BASIC_PERMS )
	end

	local url, callback, webview

	url = Facebook.AUTH_URLS[ self._view_type ]
	url = url .. '?' .. 'client_id=' .. self._app_id
	url = url .. '&' .. 'redirect_uri=' .. url_encode( self._app_url )
	url = url .. '&' .. 'response_type=' .. 'token'
	url = url .. '&' .. 'display=' .. 'touch'
	if #permissions > 0 then
		url = url .. '&' .. 'scope=' .. table.concat( permissions, ",")
	end
	-- print( url )

	callback = self:createCallback( self._loginRequest_handler )

	webview = self:_createWebView( self._view_params, callback )
	webview:request( url )

end


-- _loginRequest_handler()
-- handler for the login request
-- it's a private method, but put here for convenience
--
function Facebook:_loginRequest_handler( event )
	-- print( "Facebook:_loginRequest_handler", event )
	-- print( event.url )
	-- print( event.type, event.errorMessage )

	--== setup request handlers

	local success_f, error_f

	success_f = function( value )
		-- print( "Login: Success Handler" )
		self._access_token = value
	end

	error_f = function( response )
		-- print( "Login: Error Handler" )
		self._access_token = nil

		local evt = {
			isError = true,
			error = response.error,
			error_reason = response.error_reason,
			error_description = response.error_description,
		}
		self:_dispatchEvent( Facebook.LOGIN, evt )
	end


	-- auth process has several redirects
	-- we're only interested in the one(s) which either
	-- 1. match facebook UI dialogs
	-- 2. match our app URL
	--
	local url_parts, query_parts, fragment_parts

	url_parts = UrlLib.parse( event.url )
	-- Utils.print( url_parts )

	-- getting Facebook UI dialog
	if url_parts.path == '/login.php' and event.type == 'loaded' then
		self._webview.isVisible = true
		return

	-- getting Facebook UI dialog
	elseif url_parts.path == '/dialog/oauth' and event.type == 'loaded' then
		self._webview.isVisible = true
		return

	-- getting other
	elseif url_parts.host ~= self._app_url_parts.host then
		return
	end


	self:_removeWebView()


	query_parts = parse_query( url_parts.query )
	fragment_parts = parse_query( url_parts.fragment )
	-- print( 'URL Parts:' )
	-- Utils.print( query_parts )
	-- Utils.print( fragment_parts )


	--== handle network response

	if query_parts.error == 'access_denied' then
		error_f( query_parts )
	else
		success_f( fragment_parts.access_token )
	end

end




--[[
https://developers.facebook.com/docs/facebook-login/permissions/
--]]
function Facebook:getPermissions()
	print( "Facebook:getPermissions" )
end


function Facebook:requestPermissions( permissions, params )
	print( "Facebook:requestPermissions", permissions, params )
end

function Facebook:removePermission( permission, params )
	print( "Facebook:removePermission", permission, params )
end


function Facebook:postLink( link, params )
	-- print( "Facebook:postLink", link, params )

	params = params or {}
	params.link = link

	-- massage data in 'actions'
	if params.actions then params.actions = json.encode( params.actions ) end

	local success_f, error_f

	success_f = function( data )
		-- print( "postLink: Success Handler" )
		local evt = {
			params = params,
			data = data
		}
		self:_dispatchEvent( Facebook.POST_LINK, evt )
	end

	error_f = function( response, net_params )
		-- print( "postLink: Error Handler" )
		local evt = {
			params = params,
			isError = true,
			data = response
		}
		self:_dispatchEvent( Facebook.POST_LINK, evt )
	end

	self:_makeFacebookGraphRequest( 'me/feed', 'POST', params, success_f, error_f )
end


function Facebook:postMessage( text, params )
	-- print( "Facebook:postMessage", text, params )

	params = params or {}
	params.message = text

	local success_f, error_f

	success_f = function( data )
		-- print( "postMessage: Success Handler" )
		local evt = {
			params = params,
			data = data
		}
		self:_dispatchEvent( Facebook.POST_MESSAGE, evt )
	end

	error_f = function( response, net_params )
		-- print( "postMessage: Error Handler" )
		local evt = {
			params = params,
			isError = true,
			data = response
		}
		self:_dispatchEvent( Facebook.POST_MESSAGE, evt )
	end

	self:_makeFacebookGraphRequest( 'me/feed', 'POST', params, success_f, error_f )
end



function Facebook:request( path, method, params )
	-- print( "Facebook:request", path, method, params )

	method = method or 'GET'
	params = params or {}

	local success_f, error_f

	success_f = function( data )
		-- print( "Request Success Handler" )
		local evt = {
			path = path,
			method = method,
			params = params,
			data = data
		}
		self:_dispatchEvent( Facebook.REQUEST, evt )
	end

	error_f = function( response, net_params )
		-- print( "Request Error Handler" )
		local evt = {
			path = path,
			method = method,
			params = params,
			isError = true,
			data = response
		}
		self:_dispatchEvent( Facebook.REQUEST, evt )
	end

	self:_makeFacebookGraphRequest( path, method, params, success_f, error_f )

end



function Facebook:logout()
	-- print( "Facebook:logout" )

	local params, url, webview, callback

	url = Facebook.LOGOUT_URLS[ self._view_type ]
	url = url .. '?' .. 'next=' .. url_encode( self._app_url )
	url = url .. '&' .. 'access_token=' .. self._token
	-- print( url )

	params = { x=0, y=0, w=200, h=200 }
	callback = self:createCallback( self._logoutRequest_handler )

	webview = self:_createWebView( params, callback )
	webview:request( url )

end

-- _logoutRequest_handler()
-- handler for the logout request
-- it's a private method, but put here for convenience
--
function Facebook:_logoutRequest_handler( event )
	-- print( "Facebook:_logoutRequest_handler", event )
	-- print( event.url )
	-- print( event.type, event.errorMessage )


	-- setup handlers
	--
	local success_f, error_f

	success_f = function()
		-- print( "Request Success Handler" )
		self._access_token = nil
	end

	error_f = function( response )
		-- print( "Request Error Handler" )
		--[[
		local evt = {
			isError = true,
			error = 'error',
			error_reason = 'error_reason',
			error_description = 'error_description',
		}
		self:_dispatchEvent( Facebook.LOGOUT, evt )
	--]]
	end


	-- auth process has several redirects
	-- we're only interested in the one(s) which match our app url
	--
	local url_parts, query_parts, fragment_parts

	url_parts = UrlLib.parse( event.url )
	-- Utils.print( url_parts )

	-- getting other
	if url_parts.host ~= self._app_url_parts.host then return end


	self:_removeWebView()


	query_parts = parse_query( url_parts.query )
	fragment_parts = parse_query( url_parts.fragment )
	-- print( 'URL Parts:' )
	-- Utils.print( query_parts )
	-- Utils.print( fragment_parts )


	-- handle error/success
	--
	if not query_parts.error then
		success_f()
	else
		-- TODO: figure what can go wrong here
		error_f( {} )
	end

end




--== Private Methods ==--


-- _access_token()
-- for internal use only, set new facebook token
--
function Facebook.__setters:_access_token( value )

	local prev = self._token -- save current token for check

	self._token = value

	if value ~= nil and prev == nil then
		self:_dispatchEvent( Facebook.LOGIN, { access_token=value } )
	elseif value ~= nil and prev ~= nil then
		self:_dispatchEvent( Facebook.ACCESS_TOKEN, { access_token=value } )
	elseif value == nil and prev ~= nil then
		self:_dispatchEvent( Facebook.LOGOUT )
	end
end

--[[
function Facebook.__setters:_username( value )
	self.__username = value
end
--]]


function Facebook:_createWebView( params, listener )

	params = params or Facebook.VIEW_PARAMS

	local webview

	self:_removeWebView()

	webview = native.newWebView( params.x, params.y, params.w, params.h )

	if listener then
		webview:addEventListener( "urlRequest", listener )
		webview._f = listener
	end

	webview.isVisible = false
	self._webview = webview

	return webview
end

function Facebook:_removeWebView( params )
	-- print( "Facebook:_removeWebView" )

	local f

	if self._webview ~= nil then
		f = self._webview._f
		if f then
			self._webview._f = nil
			self._webview:removeEventListener( "urlRequest", f )
		end
		self._webview:removeSelf()
		self._webview = nil
	end
end


function Facebook:_makeFacebookGraphRequest( path, method, params, successHandler, errorHandler )
	-- print( "Facebook:_makeFacebookGraphRequest", path, method )

	-- make sure we have login already
	-- TODO: figure out how to deal with this
	--
	if not self.has_login then
		local err = Facebook.DMC_ERRORS[ 'no_login' ]
		local evt = {
			type = Facebook.DMC_ERROR_TYPE,
			code = err.code,
			message = err.message
		}
		errorHandler( evt, nil )
		return
	end

	method = method or 'GET'
	params = params or {}

	local url, callback

	-- create our graph URL
	--
	url = Facebook.GRAPH_URL
	url = url .. '/' .. path
	url = url .. '?' .. 'access_token=' .. self._token
	-- print( url )


	-- create special network callback to better handle any situation
	--
	callback = function( event )
		local net_params = {
			-- to be able to reconstruct the call
			type = 'facebook_graph', -- internal usage
			path = path,
			method = method,
			params = params,
			-- callback handlers
			successHandler = successHandler,
			errorHandler = errorHandler
		}
		self:_networkRequest_handler( event, net_params )
	end


	-- setup network request headers if necessary
	--
	local net_params, headers

	if method == 'POST' then
		net_params = {}

		net_params.body = create_query( params )
		-- print( net_params.body )
		-- print( url )

		headers = {}
		headers["Accept"] = "application/json"
		headers["Content-Type"] = "application/x-www-form-urlencoded"
		headers["Content-Length"] = string.len( net_params.body )

		net_params.headers = headers
	end


	network.request( url, method, callback, net_params )
end


function Facebook:_networkRequest_handler( event, params )
	-- print( "Facebook:_networkRequest_handler" )

	local successHandler = params.successHandler
	local errorHandler = params.errorHandler

	if event.isError then
		-- on Network Error, call error handler
		if errorHandler then errorHandler( event, params ) end

	else
		-- we got response back from server, check response

		-- print( event.response )
		local response = json.decode( event.response )


		-- on API Success
		if response and not response.error then
			if successHandler then successHandler( response ) end


		-- on API Error, handle appropriately
		else
			local err_data = response.error

			-- TODO: add API error recovery here
			-- https://developers.facebook.com/docs/reference/api/errors/
			--
			if err_data.code == 1 or err_data.code == 2 or err_data.code == 17 then
				-- server throttling, retry
				if params.type == 'facebook_graph' then
					self:_makeFacebookGraphRequest( params.path, params.method, params.params, params.successHandler, params.errorHandler )
				else
					if errorHandler then errorHandler( response.error, params ) end
				end

			-- no special case to handle error, call error handler
			else
				if errorHandler then errorHandler( response.error, params ) end
			end

		end

	end
end



function Facebook:_dispatchEvent( e_type, data )
	--print( "Facebook:_dispatchEvent" )

	data = data or {}

	-- setup custom event
	local evt = {
		name = Facebook.EVENT,
		type = e_type,
	}

	-- layer in key/value pairs
	for k,v in pairs( data ) do
		-- print(k,v)
		evt[k] = v
	end

	self:dispatchEvent( evt )
end



--====================================================================--
-- Facebook Singleton
--====================================================================--

Facebook_Singleton = Facebook:new()

return Facebook_Singleton


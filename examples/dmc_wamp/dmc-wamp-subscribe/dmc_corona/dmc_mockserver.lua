--====================================================================--
-- dmc_mockserver.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_mockserver.lua
--====================================================================--

--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

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



--====================================================================--
-- DMC Corona Library : DMC Mock Server
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.1.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


--====================================================================--
-- Support Functions

local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end


--====================================================================--
-- Configuration

local dmc_lib_data, dmc_lib_info

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_corona_boot" ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_library



--====================================================================--
-- DMC Mock Server
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_mockserver = dmc_lib_data.dmc_mockserver or {}

local DMC_MOCKSERVER_DEFAULTS = {
	-- none
}

local dmc_mockserver_data = Utils.extend( dmc_lib_data.dmc_mockserver, DMC_MOCKSERVER_DEFAULTS )


--====================================================================--
-- Imports


local Files = require 'dmc_files'
local json = require 'json'
local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase



--====================================================================--
-- Mock Server Class
--====================================================================--


local MockServer = inheritsFrom( CoronaBase )
MockServer.NAME = "DMC Library Mock Server"

MockServer.REQUEST_DELAY = 500 -- milliseconds


--====================================================================--
--== Start: Setup DMC Objects

function MockServer:_init( params )
	-- print( "MockServer:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Create Properties ==--

	self._base_path = params.base_path

	self._network = _G.network
	self._filter = nil -- filter function
	self._actions = nil -- table of possible responses

	--== Display Groups ==--

	--== Object References ==--

end

-- _initComplete()
--
function MockServer:_initComplete()
	-- print( "MockServer:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	self._actions = {}

	-- setup network.* API on object
	self.request = self:createCallback( self._request )

	self:addFilter( function( url, method ) return true end )

end

function MockServer:_undoInitComplete()
	--==--
	self:superCall( "_undoInitComplete" )
end

--== END: Setup DMC Objects
--====================================================================--


--====================================================================--
--== Public Methods

function MockServer:respondWith( method, url, response )
	-- print( "MockServer:respondWith", method, url, response )

	local resp_hash = self._actions
	local resp_list

	if not resp_hash[ method ] then resp_hash[ method ] = {} end
	resp_list = resp_hash[ method ]

	resp_list[ url ] = response

end


function MockServer:addFilter( func )
	-- print( "MockServer:addFilter", func  )

	self._filter = func

end


--====================================================================--
--== Private Methods

function MockServer:_findResponse( url, method )
	-- print( "MockServer:_findResponse", url, method  )

	local action_list = self._actions[ method ]
	local action = nil
	local response = nil

	for k,v in pairs( action_list ) do

		if k == url then
			action = v
			break
		end

	end

	-- add data, event
	if action then

		local path = table.concat( { self._base_path, action[3] }, '/' )
		local file_path = system.pathForFile( path, system.ResourceDirectory )

		local data = Files.readJSONFile( file_path )
		local json_data = json.encode( data )

		-- todo, change depending on json, html

		response = {}

		response.event = {
			name='networkRequest',
			phase='ended',

			responseType='text',
			responseHeaders=action[2],
			url=url,
			bytesTransferred=#json_data,

			status=action[1], -- 200, etc
			response=json_data, -- json encoded data
			isError=false,

			requestId='??',
		}


	end

	return response

end

function MockServer:_mockHandlesRequest( url, method )

	local response = true

	if self._filter then
		response = self._filter( url, method )
	end

	return response
end

function MockServer:_request( url, method, callback, params )
	-- print( "MockServer:_request", url, method  )

	local passthru = MockServer.PASSTHRU_HASH[ method ]
	local f

	if self:_mockHandlesRequest( url, method ) then
		f = function()
			self:_respond( url, method, callback, params )
		end
		timer.performWithDelay( self.REQUEST_DELAY, f )

	else
		-- do real call
		return self._network.request( url, method, callback, params )
	end

end


--====================================================================--
--== Event Handlers

-- none



return MockServer

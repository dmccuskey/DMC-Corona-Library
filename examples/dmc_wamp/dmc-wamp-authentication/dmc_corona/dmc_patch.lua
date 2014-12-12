--====================================================================--
-- dmc_patch.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_patch.lua
--====================================================================--

--[[

Copyright (C) 2014 David McCuskey. All Rights Reserved.

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
-- DMC Corona Library : DMC Patch
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.1"



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
-- DMC Patch
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_patch = dmc_lib_data.dmc_patch or {}

local DMC_PATCH_DEFAULTS = {
	string_formatting_active=true,
	advanced_require_active=false,
	table_pop=true
}

local dmc_patch_data = Utils.extend( dmc_lib_data.dmc_patch, DMC_PATCH_DEFAULTS )


--====================================================================--
-- Imports

local Utils = require 'lua_utils'


--====================================================================--
-- Setup, Constants

local gRequire = _G.require -- save copy



--====================================================================--
-- Patch Work
--====================================================================--


--====================================================================--
--== Python-style string formatting

if dmc_patch_data.string_formatting_active == true then
	getmetatable("").__mod = Utils.stringFormatting
end


--====================================================================--
--== Python-style table pop() method

if dmc_patch_data.table_pop == true then
	table.pop = function( t, v )
		local res = t[v]
		t[v] = nil
		return res
	end
end


--====================================================================--
--== Advanced require()

local function init()

	local gRequire = _G.require
	local dirs = { '', 'libs.' }

	return function( module_name )
		local found, name, g_error
		for i,v in ipairs( dirs )  do
			found, name, g_error = nil, nil, nil
			local name = v .. module_name
			local try = function()
				found = gRequire( name )
			end
			-- print( name )
			local status, err = pcall( try )

			if status then
				break
			else
				-- print( err )
				if string.find( err, "^error loading module") ~= nil then
					-- print("ERORR loading")
					g_error = err
					break

				elseif string.find( err, "module '.+' not found:resource" ) then
					-- print("NOT FOUND")
					if not g_error then
						g_error = err
					end

				else
					g_error = err
					break
				end
			end
		end

		if found then
			return found
		else
			print( "error importing '%s'" % tostring( module_name ) )
			-- print( g_error )
			error( g_error )
		end

	end

end

if dmc_patch_data.advanced_require_active == true then
	_G.require = init()
end




return {
	-- future facade
}

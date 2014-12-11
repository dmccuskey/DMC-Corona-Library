--====================================================================--
-- dmc_require.lua
--
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_require.lua
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
-- DMC Corona Library : DMC Require
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Setup, Constants

local LOCAL_DEBUG = false


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

function Utils.sysPathToRequirePath( sys_path )
	-- print( "sysPathToRequirePath", sys_path)
	local sys_tbl = Utils.split( sys_path, Utils.getSystemSeparator() )
	-- clean off any dots
	for i=#sys_tbl, 1, -1 do
		if sys_tbl[i]=='.' then
			table.remove( sys_tbl, i )
		end
	end
	return table.concat( sys_tbl, '.' )
end



local patchedRequire = function( module_name )
	-- print( "dmc_require: ", module_name )
	assert( type(module_name)=='string', "dmc_require: expected string module name" )
	--==--
	local resource_path = system.pathForFile( system.ResourceDirectory ) or ""

	local _paths = _G.__dmc_require.paths
	local _require = _G.__dmc_require.require
	local lua_paths = Utils.extend( _paths, {} )
	table.insert( lua_paths, 1, '' ) -- add search at root-level

	local err_tbl = {}
	local library = nil
	local idx = 1
	repeat
		local mod_path = lua_paths[idx]
		local path = ( mod_path=='' and mod_path or mod_path..'.' ) .. module_name

		local has_module, result = pcall( _require, path )
		if has_module then
			library = result
		else
			if string.find( result, '^error loading module' ) then
				print( result )
				error( result, 2 )
			else
				table.insert( err_tbl, resource_path..'/'..mod_path )
				table.insert( err_tbl, result )
			end
		end

		idx=idx+1
	until library or idx > #lua_paths

	if not library then
		table.insert( err_tbl, 1, "module '".. module_name.."' not found in archive:" )
		-- print( table.concat( err_tbl, '\n' ) )
		error( table.concat( err_tbl, '\n' ), 2 )
	end

	return library
end



--====================================================================--
-- Require Mgr Class
--====================================================================--


local RequireMgr = {}

function RequireMgr:_initialize()
	if _G.__dmc_require then return end
	print( "dmc_require: initializing")

	-- setup structure
	_G.__dmc_require = {
		paths={},
		require=_G.require -- original require method
	}

	_G.require = patchedRequire
end

function RequireMgr:prependPath( path )
	-- print( "RequireMgr:prependPath" )
	assert( type(path)=='string', "expected string for path")
	--==--
	table.insert( _G.__dmc_require.paths, 1, Utils.sysPathToRequirePath( path ) )
end

function RequireMgr:appendPath( path )
	-- print( "RequireMgr:appendPath" )
	assert( type(path)=='string', "expected string for path")
	--==--
	table.insert( _G.__dmc_require.paths, Utils.sysPathToRequirePath( path ) )
end


RequireMgr:_initialize()

return RequireMgr

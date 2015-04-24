--====================================================================--
-- dmc_corona/dmc_path.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2015 David McCuskey

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
--== DMC Corona Library : DMC Patch
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--


--====================================================================--
--== Support Functions


local Utils = {} -- make copying from Utils easier


--== Start: copy from lua_utils ==--

-- extend()
-- Copy key/values from one table to another
-- Will deep copy any value from first table which is itself a table.
--
-- @param fromTable the table (object) from which to take key/value pairs
-- @param toTable the table (object) in which to copy key/value pairs
-- @return table the table (object) that received the copied items
--
function Utils.extend( fromTable, toTable )

	if not fromTable or not toTable then
		error( "table can't be nil" )
	end
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

--== End: copy from lua_utils ==--



--====================================================================--
--== Configuration


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona



--====================================================================--
--== DMC Patch
--====================================================================--


--====================================================================--
--== Configuration


dmc_lib_data.dmc_patch = dmc_lib_data.dmc_patch or {}

local DMC_PATCH_DEFAULTS = {
}

local dmc_patch_data = Utils.extend( dmc_lib_data.dmc_patch, DMC_PATCH_DEFAULTS )


local assert = assert
local sfind = string.find
local sgmatch = string.gmatch
local smatch = string.match
local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove
local type = type



--====================================================================--
--== Imports


local Utils = {}


function Utils.guessPathPlatform( path )

	local win, ios = 0, 0
	for match in sgmatch( path, '\\' ) do
		win=win+1
	end
	for match in sgmatch( path, '/' ) do
		ios=ios+1
	end
	if win>ios then
		return '\\'
	else
		return '/'
	end
end


function Utils.getPath( pathObj, filePath )
	-- print( "Utils.getPath", pathObj, filePath )
	if filePath==nil then filePath='' end
	--==--
	local fileInfo = Utils.parse( filePath )
	fileInfo.dir = pathObj.dir
	return Utils.buildPath( fileInfo )
end


-- split string up in parts, using separator
-- returns array of pieces
function Utils.split( str, sep )
	if sep == nil then
		sep = "%s"
	end
	local t, i = {}, 1
	for str in sgmatch( str, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

function Utils.parse( filePath, sep )
	-- print("Utils.parse", filePath )
	if sep==nil then sep=Utils.guessPathPlatform( filePath ) end
	--==--
	local isAbs = false
	local parts, last
	local filename, name, ext

	if sfind( filePath, sep )==1 then
		isAbs=true
	end
	parts = Utils.split( filePath, sep )
	last = parts[#parts] or ''
	if smatch( last, '[%.]' ) then
		filename = tremove( parts, #parts )
		name, ext = smatch( filename, '(.+)%.([^%.]+)$' )
	end

	return {
		original=filePath,
		isAbs=isAbs,
		dir={},
		path=parts,
		filename=filename,
		name=name,
		ext=ext,

		getPath = Utils.getPath
	}

end


function Utils._concatPath( params )
	local dir = params.dir or {}
	local isAbs = params.isAbs or false
	local name = params.name
	local path = params.path or {}
	local sep = params.sep
	--==--
	local res = {}
	if isAbs then
		tinsert( res, '' )
	end
	if #dir>0 then
		tinsert( res, tconcat( dir, sep ) )
	end
	if #path>0 then
		tinsert( res, tconcat( path, sep ) )
	end
	if name then
		tinsert( res, name )
	end
	return tconcat( res, sep )
end

function Utils.buildRequire( parts, sep )
	assert( type(parts)=='table' )
	if sep==nil then sep='.' end
	return Utils._concatPath{
		dir=parts.dir,
		path=parts.path,
		name=parts.name,
		sep=sep,
		isAbs=parts.isAbs
	}
end

function Utils.buildPath( parts, sep )
	assert( type(parts)=='table' )
	-- @TODO: do separator
	if sep==nil then sep='/' end
	return Utils._concatPath{
		dir=parts.dir,
		path=parts.path,
		name=parts.filename,
		sep=sep,
		isAbs=parts.isAbs
	}
end




return Utils

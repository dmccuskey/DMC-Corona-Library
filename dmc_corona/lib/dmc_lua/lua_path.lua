--====================================================================--
-- lua_path.lua
--
-- Documentation: https://github.com/dmccuskey/lua-path
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
--== DMC Lua Library : Lua Path
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.0"



--====================================================================--
--== Setup, Constants


local assert = assert
local sgmatch = string.gmatch
local sgsub = string.gsub
local smatch = string.match
local ssub = string.sub
local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove
local type = type



--====================================================================--
--== Support Functions


-- escape every non-alphanumeric character, so the string
-- matches itself in a pattern
local function escapePattern( str )
	return ( sgsub( str, '(%W)', '%%%1' ) )
end



--====================================================================--
--== Path Facade
--====================================================================--


local Path = {
	__version=VERSION
}


-- guessPathPlatform()
-- returns the separator used most in path: '\\' or '/'
--
function Path.guessPathPlatform( path )

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


-- getPath()
-- returns filePath placed in the folder of pathObj, a table from parse()
-- (its dir and path), with pathObj's separator
-- an absolute filePath is returned as it is
--
function Path.getPath( pathObj, filePath )
	-- print( "Path.getPath", pathObj, filePath )
	if filePath==nil then filePath='' end
	--==--
	local fileInfo = Path.parse( filePath )
	if fileInfo.isAbs then return Path.buildPath( fileInfo ) end

	local dir = {}
	for _, part in ipairs( pathObj.dir or {} ) do
		tinsert( dir, part )
	end
	for _, part in ipairs( pathObj.path or {} ) do
		tinsert( dir, part )
	end
	fileInfo.dir = dir
	fileInfo.isAbs = pathObj.isAbs
	fileInfo.sep = pathObj.sep
	return Path.buildPath( fileInfo )
end


-- split()
-- split string up in parts, using a one-character separator
-- (default: any whitespace)
-- returns array of pieces
--
function Path.split( str, sep )
	local pattern
	if sep == nil then
		pattern = "%s"
	else
		pattern = escapePattern( sep )
	end
	local t, i = {}, 1
	for part in sgmatch( str, "([^"..pattern.."]+)") do
		t[i] = part
		i = i + 1
	end
	return t
end


-- parse()
-- break a file path (or a require string, with sep '.') into its parts
-- sep is guessed from the path when not given
--
function Path.parse( filePath, sep )
	-- print("Path.parse", filePath )
	assert( type(filePath)=='string', "parse: expected string for filePath" )
	if sep==nil then sep=Path.guessPathPlatform( filePath ) end
	--==--
	local isAbs = false
	local parts, last
	local filename, name, ext

	if ssub( filePath, 1, #sep )==sep then
		isAbs=true
	end
	parts = Path.split( filePath, sep )
	last = parts[#parts] or ''
	if smatch( last, '[%.]' ) then
		filename = tremove( parts, #parts )
		name, ext = smatch( filename, '(.+)%.([^%.]+)$' )
	end

	return {
		original=filePath,
		isAbs=isAbs,
		sep=sep,
		dir={},
		path=parts,
		filename=filename,
		name=name,
		ext=ext,

		getPath = Path.getPath
	}

end


function Path._concatPath( params )
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


-- buildRequire()
-- returns a require string from a table from parse()
--
function Path.buildRequire( parts, sep )
	assert( type(parts)=='table' )
	if sep==nil then sep='.' end
	return Path._concatPath{
		dir=parts.dir,
		path=parts.path,
		name=parts.name,
		sep=sep,
		isAbs=parts.isAbs
	}
end


-- buildPath()
-- returns a file path from a table from parse()
-- sep defaults to '\\' for a path parsed with '\\', otherwise '/'
--
function Path.buildPath( parts, sep )
	assert( type(parts)=='table' )
	if sep==nil then
		if parts.sep=='\\' then sep='\\' else sep='/' end
	end
	return Path._concatPath{
		dir=parts.dir,
		path=parts.path,
		name=parts.filename,
		sep=sep,
		isAbs=parts.isAbs
	}
end




return Path

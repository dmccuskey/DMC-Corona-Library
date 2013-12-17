--====================================================================--
-- dmc_kolor.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_kolor.lua
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


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.1"



--====================================================================--
-- Boot Support Methods
--====================================================================--

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
-- DMC Library Config
--====================================================================--

local dmc_lib_data, dmc_lib_info, dmc_lib_location

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_library_boot" ) end ) then
	_G.__dmc_library = {
		dmc_library={
			location = ''
		},
		func = {
			find=function( name )
				local loc = ''
				if dmc_lib_data[name] and dmc_lib_data[name].location then
					loc = dmc_lib_data[name].location
				else
					loc = dmc_lib_info.location
				end
				if loc ~= '' and string.sub( loc, -1 ) ~= '.' then
					loc = loc .. '.'
				end
				return loc .. name
			end
		}
	}
end

dmc_lib_data = _G.__dmc_library
dmc_lib_func = dmc_lib_data.func
dmc_lib_info = dmc_lib_data.dmc_library
dmc_lib_location = dmc_lib_info.location




--====================================================================--
-- DMC Library : DMC Kolor
--====================================================================--



--====================================================================--
-- DMC Kolor Config
--====================================================================--

dmc_lib_data.dmc_kolor = dmc_lib_data.dmc_kolor or {}

local DMC_KOLOR_DEFAULTS = {
	default_color_space='RGB',
	cache_is_active=false,
	make_global=false,
	-- named_color_file, no default,
	-- named_color_format, no default,
}

local dmc_kolor_data = Utils.extend( dmc_lib_data.dmc_kolor, DMC_KOLOR_DEFAULTS )



--====================================================================--
-- Imports
--====================================================================--

local json = require( 'json' )


-- only needed for debugging
-- Utils2 = require( dmc_lib_func.find('dmc_utils') )



--====================================================================--
-- Setup, Constants
--====================================================================--

local NAMED_COLORS = nil  -- table of colors
local CACHED_COLORS = {}  -- table of cached colors

local _DISPLAY = _G.display -- reference to the original display object

local Display, Kolor



--====================================================================--
-- Support Methods
--====================================================================--


Utils.IO_ERROR = "io_error"
Utils.IO_SUCCESS = "io_success"

function Utils.readFile( file_path, options )
	-- print( "Utils.readFile", file_path )

	options = options or {}
	if options.lines == nil then options.lines = true end

	local contents -- either string or table of strings
	local ret_val = {} -- an array, [ status, content ]

	if file_path == nil then
		local ret_val = { Utils.IO_ERROR, "file path is NIL" }

	else
		local fh, reason = io.open( file_path, "r" )
		if fh == nil then
			print("ERROR: datastore load settings: " .. tostring( reason ) )
			ret_val = { Utils.IO_ERROR, reason }

		else
			if options.lines == false then
				-- read contents in one big string
				contents = fh:read( '*all' )

			else
				-- read all contents of file into a table
				contents = {}
				for line in fh:lines() do
					table.insert( contents, line )
				end

			end

			ret_val = { Utils.IO_SUCCESS, contents }
			io.close( fh )

		end  -- fh == nil
	end  -- file_path == nil

	return ret_val[1], ret_val[2]
end



function readInNamedColors( file, format )
	-- print( 'readInNamedColors' )

	local options = options or {}
	options.lines = false

	local file_path, status, data
	file_path = system.pathForFile( file, system.ResourceDirectory )

	if file_path ~= nil then
		status, data = Utils.readFile( file_path, options )
		if status == Utils.IO_ERROR then
			NAMED_COLORS = nil
		else
			NAMED_COLORS = json.decode( data )
		end
	end

	function RGBToHDR( colors )
		-- print( 'RGBToHDR' )
		for k,v in pairs( colors ) do
			colors[k] = { v[1]/255, v[2]/255, v[3]/255, v[4] }
			-- print( colors[k][1], colors[k][2], colors[k][3], colors[k][4] )
		end
	end
	function HEXToHDR( colors )
		-- print( 'HEXToHDR' )
		for k,v in pairs( colors ) do
			local hex, alpha
			if type(v) == 'table' then
				hex, alpha = v[1], v[2]
			else
				hex, alpha = v, nil
			end
			colors[k] = {
				tonumber( string.sub( hex, 1, 2 ), 16 )/255,
				tonumber( string.sub( hex, 3, 4 ), 16 )/255,
				tonumber( string.sub( hex, 5, 6 ), 16 )/255,
				alpha
			}
			--[[
			-- output RGB, for creating named color file
			colors[k] = {
				tonumber( string.sub( hex, 1, 2 ), 16 ),
				tonumber( string.sub( hex, 3, 4 ), 16 ),
				tonumber( string.sub( hex, 5, 6 ), 16 ),
				alpha
			}
			--]]
			-- print( colors[k][1], colors[k][2], colors[k][3], colors[k][4] )
		end
	end

	--[[
	-- for creating named color file
	function outputToJSON( colors )
		-- print( 'outputToJSON' )

		local format = 'HDR' -- HDR, RGB
		local final, str = "", ""
		local sorter = {}
		local new_colors = {}
		for k,v in pairs( colors ) do
			table.insert( sorter, k )
			str = '\n"'..k..'": [ ' .. table.concat( { colors[k][1], colors[k][2], colors[k][3] }, ', ' ) .. ' ],'
			new_colors[k] = str
		end

		table.sort(sorter)

		for i,v in ipairs( sorter ) do
			str = new_colors[v]
			final = final .. str
		end

		print( final )

	end
--]]

	if NAMED_COLORS ~= nil then
		if dmc_kolor_data.named_color_format == 'HEX' then
			HEXToHDR( NAMED_COLORS )
		elseif dmc_kolor_data.named_color_format == 'RGB' then
			RGBToHDR( NAMED_COLORS )
		end
		-- to create named files
		-- outputToJSON( NAMED_COLORS )
	end


end


-- if we have file with named colors then process it
--
if dmc_kolor_data.named_color_file and dmc_kolor_data.named_color_format then
	readInNamedColors( dmc_kolor_data.named_color_file, dmc_kolor_data.named_color_format )
end



function translateRGBToHDR( ... )
	-- print( 'translateRGBToHDR' )

	local args = { ... }
	local color

	if type( args[2] ) == 'number' then

		-- regular RGB
		color = { args[2]/255, args[3]/255, args[4]/255, args[5] }

	elseif type( args[2] ) == 'table' and args[2].type=='gradient' then

		-- gradient RGB
		t = args[2].color1
		args[2].color1 = { t[1]/255, t[2]/255, t[3]/255, t[4] }

		t = args[2].color2
		args[2].color2 = { t[1]/255, t[2]/255, t[3]/255, t[4] }

		color = { args[2] }

	elseif type( args[2] ) == 'string' then

		-- named color
		color = NAMED_COLORS and NAMED_COLORS[ args[2] ]
		if not color then
			color = { 1, 1, 1 }
			print('\n')
			print( 'ERROR dmc_kolor: named color not found', tostring( args[2] ) )
			print('\n')
		end
		color[4] = args[3]

	else
		print('\n')
		print( 'ERROR dmc_kolor: invalid RGB color type', type( args[2] ) )
		print('\n')
	end

	-- print( color[1], color[2], color[3], color[4] )

	return color
end



-- gives back methods, but will work with named colors, defined in HDR
--
function translateHDRToHDR( ... )
	-- print( 'translateHDRToHDR' )

	local args = { ... }
	local color

	if type( args[2] ) == 'number' then

		-- regular HDR
		color = { args[2], args[3], args[4], args[5] }

	elseif type( args[2] ) == 'table' and args[2].type=='gradient' then

		-- gradient HDR
		color = { args[2] }

	elseif type( args[2] ) == 'string' then

		-- named color HDR
		color = NAMED_COLORS and NAMED_COLORS[ args[2] ]
		if not color then
			color = { 1, 1, 1 }
			print('\n')
			print( 'ERROR dmc_kolor: named color not found', tostring( args[2] ) )
			print('\n')
		end
		color[4] = args[3]

	else
		print('\n')
		print( 'ERROR dmc_kolor: invalid HDR color type', type( args[2] ) )
		print('\n')
	end

	return color
end



--====================================================================--
-- Display Class Setup
--====================================================================--

Display = {}

setmetatable( Display, { __index=_DISPLAY } )


-- imbue object with fillColor magic
--
function Display._modifySetFillColor( o )
	-- print( 'modifySetFillColor' )

	-- cached version
	--[[
	function createClosure( obj, translate )
		local f = function( ... )
			local args = { ... }
			local key, color
			if type( args[2] ) == 'number' and dmc_kolor_data.cache_is_active == true then
				-- check cache
				key = table.concat( { tostring(args[2]), tostring(args[3]), tostring(args[4]), tostring(args[5]) }, '-' )
				color = CACHED_COLORS[key]
			end
			if color == nil then
				color = translate( ... )
				if key then CACHED_COLORS[ key ] = color end
			end
			-- print( color[1], color[2], color[3], color[4] )
			obj:_setFillColor( unpack( color ) )
		end
		return f
	end
	--]]

	function createClosure( obj, translate )
		local f = function( ... )
			local color = translate( ... )
			obj:_setFillColor( unpack( color ) )
		end
		return f
	end

	o._setFillColor = o.setFillColor

	o.setFillRGB = createClosure( o, translateRGBToHDR )
	o.setFillHDR = createClosure( o, translateHDRToHDR )

end


-- imbue object with strokeColor magic
--
function Display._modifySetStrokeColor( o )
	-- print( 'Display._modifySetStrokeColor' )

	-- cached version
	--[[
	function createClosure( obj, translate )
		local f = function( ... )
			local args = { ... }
			local key, color
			if type( args[2] ) == 'number' and dmc_kolor_data.cache_is_active == true then
				-- check cache
				key = table.concat( { tostring(args[2]), tostring(args[3]), tostring(args[4]), tostring(args[5]) }, '-' )
				color = CACHED_COLORS[key]
			end
			if color == nil then
				color = translate( ... )
				if key then CACHED_COLORS[ key ] = color end
			end
			-- print( color[1], color[2], color[3], color[4] )
			obj:_setStrokeColor( unpack( color ) )
		end
		return f
	end
	--]]

	function createClosure( obj, translate )
		-- print('createClosure stroke')
		local f = function( ... )
			local color = translate( ... )
			obj:_setStrokeColor( unpack( color ) )
		end
		return f
	end

	o._setStrokeColor = o.setStrokeColor

	o.setStrokeRGB = createClosure( o, translateRGBToHDR )
	o.setStrokeHDR = createClosure( o, translateHDRToHDR )

end



function Display.newCircle( ... )
	-- print( 'Display.newCircle' )

	local o = _DISPLAY.newCircle( ... )

	Display._modifySetFillColor( o )
	Display._modifySetStrokeColor( o )

	return o
end


function Display.newLine( ... )
	-- print( 'Display.newLine' )

	local o = _DISPLAY.newLine( ... )

	Display._modifySetStrokeColor( o )

	return o
end


function Display.newPolygon( ... )
	-- print( 'Display.newPolygon' )

	local o = _DISPLAY.newPolygon( ... )

	Display._modifySetFillColor( o )
	Display._modifySetStrokeColor( o )

	return o
end


function Display.newRect( ... )
	-- print( 'Display.newRect' )

	local o = _DISPLAY.newRect( ... )

	Display._modifySetFillColor( o )
	Display._modifySetStrokeColor( o )

	return o
end


function Display.newRoundedRect( ... )
	-- print( 'Display.newRoundedRect' )

	local o = _DISPLAY.newRoundedRect( ... )

	Display._modifySetFillColor( o )
	Display._modifySetStrokeColor( o )

	return o
end


function Display.newText( ... )
	-- print( 'Display.newText' )

	local o = _DISPLAY.newText( ... )

	Display._modifySetFillColor( o )
	Display._modifySetStrokeColor( o )

	return o
end



--====================================================================--
-- Kolor Class Setup
--====================================================================--

Kolor = {}
setmetatable( Kolor, { __index=Display } )


function Kolor.newCircle( ... )
	-- print( 'Kolor.newCircle' )

	local o = Display.newCircle( ... )

	-- set the default behavior
	if dmc_kolor_data.default_color_space == 'HDR' then
		o.setStrokeColor = o.setStrokeHDR
		o.setFillColor = o.setFillHDR
	else
		o.setStrokeColor = o.setStrokeRGB
		o.setFillColor = o.setFillRGB
	end

	return o
end


function Kolor.newLine( ... )
	-- print( 'Kolor.newLine' )

	local o = Display.newLine( ... )

	-- set the default behavior
	print( '\n' )
	print( 'WARNING dmc_kolor: there is a bug in Corona newLine. use setStrokeRGB() instead' )
	print( '\n' )
	--[[
	if dmc_kolor_data.default_color_space == 'HDR' then
		o.setStrokeColor = o.setStrokeHDR
	else
		o.setStrokeColor = o.setStrokeRGB
	end
	--]]

	return o
end


function Kolor.newPolygon( ... )
	-- print( 'Kolor.newPolygon' )

	local o = Display.newPolygon( ... )

	if dmc_kolor_data.default_color_space == 'HDR' then
		o.setStrokeColor = o.setStrokeHDR
		o.setFillColor = o.setFillHDR
	else
		o.setStrokeColor = o.setStrokeRGB
		o.setFillColor = o.setFillRGB
	end

	return o
end


function Kolor.newRect( ... )
	-- print( 'Kolor.newRect' )

	local o = Display.newRect( ... )

	if dmc_kolor_data.default_color_space == 'HDR' then
		o.setStrokeColor = o.setStrokeHDR
		o.setFillColor = o.setFillHDR
	else
		o.setStrokeColor = o.setStrokeRGB
		o.setFillColor = o.setFillRGB
	end

	return o
end


function Kolor.newRoundedRect( ... )
	-- print( 'Kolor.newRoundedRect' )

	local o = Display.newRoundedRect( ... )

	if dmc_kolor_data.default_color_space == 'HDR' then
		o.setStrokeColor = o.setStrokeHDR
		o.setFillColor = o.setFillHDR
	else
		o.setStrokeColor = o.setStrokeRGB
		o.setFillColor = o.setFillRGB
	end

	return o
end


function Kolor.newText( ... )
	-- print( 'Kolor.newText' )

	local o = Display.newText( ... )

	if dmc_kolor_data.default_color_space == 'HDR' then
		o.setStrokeColor = o.setStrokeHDR
		o.setFillColor = o.setFillHDR
	else
		o.setStrokeColor = o.setStrokeRGB
		o.setFillColor = o.setFillRGB
	end

	return o
end



--====================================================================--
-- Final Setup
--====================================================================--

-- replace original display object with one of ours

if dmc_kolor_data.make_global == true then
	_G.display = Kolor
else
	_G.display = Display
end


return Kolor

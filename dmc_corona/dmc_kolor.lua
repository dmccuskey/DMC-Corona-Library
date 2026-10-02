--====================================================================--
-- dmc_kolor.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-kolor
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : DMC Kolor
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.1.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Configuration


local dmc_lib_data, dmc_lib_info

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
--== DMC Kolor
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_kolor = dmc_lib_data.dmc_kolor or {}

local DMC_KOLOR_DEFAULTS = {
	default_color_format='dRGBA',
	-- named_color_file, no default,
}

-- the settings from dmc_corona.cfg, over the defaults
local dmc_kolor_data = {}
for k, v in pairs( DMC_KOLOR_DEFAULTS ) do dmc_kolor_data[ k ] = v end
for k, v in pairs( dmc_lib_data.dmc_kolor ) do dmc_kolor_data[ k ] = v end



--====================================================================--
--== Imports


-- none



--====================================================================--
--== Setup, Constants


local sfmt = string.format
local slower = string.lower
local tostr = tostring

local Kolor



--====================================================================--
--== Support Functions


local function initialize()
	-- print( "Kolor Initialize" )

	Kolor.setColorFormat( dmc_kolor_data.default_color_format )

	if dmc_kolor_data.named_color_file then
		Kolor.importColorFile( dmc_kolor_data.named_color_file )
	end

end


-- raise an error about a color; translateColor() raises it again
-- at the caller's line
--
local function check( ok, msg, ... )
	if not ok then error( "dmc_kolor: "..sfmt( msg, ... ), 0 ) end
end

local function copyColor( c_tbl )
	return { c_tbl[1], c_tbl[2], c_tbl[3], c_tbl[4] }
end


--== Test Functions

local function dAToTest( value )
	return value
end

local function RGBToTest( value )
	return value
end


--== Alpha to HDR

local function dAToHDR( value )
	check( type(value)=='number' and value>=0 and value<=1,
		"alpha must be a number from 0 to 1, got %s", tostr(value) )
	return value
end

local function hAToHDR( value )
	check( type(value)=='number' and value>=0 and value<=255,
		"alpha must be a number from 0 to 255, got %s", tostr(value) )
	return value/255
end


--== RGB to HDR

-- returns a function translating a table of color values, each
-- 0 to max, with alpha_f for the alpha, into a new table of 0-1 values
-- { grey }, { grey, alpha }, { r, g, b } and { r, g, b, alpha } work
--
local function makeRGBToHDR( max, alpha_f )

	local function component( value )
		check( type(value)=='number' and value>=0 and value<=max,
			"color value must be a number from 0 to %d, got %s", max, tostr(value) )
		return value/max
	end

	return function( c_tbl )
		local r, g, b, a
		if c_tbl[2]==nil then
			-- greyscale
			r, g, b = c_tbl[1], c_tbl[1], c_tbl[1]
		elseif c_tbl[3]==nil then
			-- greyscale with alpha
			r, g, b, a = c_tbl[1], c_tbl[1], c_tbl[1], c_tbl[2]
		else
			r, g, b, a = c_tbl[1], c_tbl[2], c_tbl[3], c_tbl[4]
		end
		if a~=nil then a = alpha_f( a ) end
		return { component( r ), component( g ), component( b ), a }
	end
end


--== Hex String to HDR

-- #FF00FF to { 1, 0, 1 }
-- also #F0F, #F0F8 and #FF00FF80, with the alpha in hex
-- alpha, if given, is translated with alpha_f and replaces a hex alpha
--
local function HexToHDR( hex, alpha, alpha_f )
	-- print( "HexToHDR", hex, alpha )
	local value = hex:match( '^#(%x+)$' )
	local len = value and #value
	check( len==3 or len==4 or len==6 or len==8,
		"hex color must be #RGB, #RGBA, #RRGGBB or #RRGGBBAA, got '%s'", hex )
	if len<=4 then
		value = value:gsub( '%x', '%0%0' )
	end
	local c = {}
	for i = 1, #value/2 do
		c[i] = tonumber( value:sub( i*2-1, i*2 ), 16 ) / 255
	end
	if alpha~=nil then c[4] = alpha_f( alpha ) end
	return c
end




--====================================================================--
--== Kolor Setup
--====================================================================--


Kolor = {}

Kolor.VERSION = VERSION

Kolor.dRGBA ='dRGBA'
Kolor.hRGBA ='hRGBA'
Kolor.hRGBdA ='hRGBdA'

Kolor._NAMED_COLORS = nil -- set to table when loaded

Kolor._VALID_FORMATS = {
	Kolor.dRGBA,
	Kolor.hRGBA,
	Kolor.hRGBdA,
}
Kolor._DEFAULT_FORMAT = Kolor.dRGBA


--== Set during initialize()
Kolor._FORMAT = nil -- set format
Kolor._COLOR_FUNC = nil -- color trans function
Kolor._ALPHA_FUNC = nil -- alpha trans function

Kolor._RUN_MODE = 'run'
Kolor.isTesting = Kolor._RUN_MODE=='test'


--====================================================================--
--== Public Functions


--== Initialize Kolor Set

-- the format is set back even if func raises an error
--
function Kolor.initializeKolorSet( func, mode )
	-- print( "Kolor.initializeKolorSet", mode )
	assert( func, "Kolor.initializeKolorSet requires function" )
	mode = mode or Kolor.dRGBA
	--==--
	local format = Kolor.getColorFormat()
	Kolor.setColorFormat( mode )
	local ok, err = pcall( func )
	Kolor.setColorFormat( format )
	if not ok then error( err, 0 ) end
end

function Kolor.setRunMode( mode )
	Kolor._RUN_MODE = mode
	Kolor.isTesting = ( Kolor._RUN_MODE=='test' )
	if Kolor._FORMAT then Kolor.setColorFormat( Kolor._FORMAT ) end
end


--== Color Format

function Kolor.getColorFormat()
	return Kolor._FORMAT
end

function Kolor.setColorFormat( value )
	-- print( "Kolor.setColorFormat", value )
	assert( type(value)=='string', sfmt( "Kolor.setColorFormat, expected type 'string', got '%s'", tostr(type(value)) ))
	--==--
	local c, a = Kolor._getTranslateFunctions( value )

	Kolor._FORMAT = value
	Kolor._COLOR_FUNC = c
	Kolor._ALPHA_FUNC = a
end


--== Color Translation

-- colors ( 5,5,5,5 ), { 5,5,5,5 }, '#FF00FF', 'Navy', a gradient
-- returns a new table; an error is raised at the caller's line
--
function Kolor.translateColor(...)
	local arg1 = ...
	local arg1Type = type(arg1)
	local ok, color

	if arg1Type=='nil' then
		return nil
	elseif arg1Type=='table' and arg1.type==nil then
		-- not gradient
		ok, color = pcall( Kolor._translateColor, arg1 )
	else
		ok, color = pcall( Kolor._translateColor, {...} )
	end
	if not ok then error( color, 2 ) end

	return color
end

function Kolor.translateAlpha( alpha )
	if not alpha then return alpha end
	local ok, value = pcall( Kolor._ALPHA_FUNC, alpha )
	if not ok then error( value, 2 ) end
	return value
end


--======================================================--
-- Named-Color Functions

function Kolor.purgeNamedColors()
	Kolor._NAMED_COLORS = nil
end

-- Lua path, 'colors.data_file'
function Kolor.importColorFile( path )
	assert( type(path)=='string' )
	--==--
	local cf = require( path )
	cf.initialize( Kolor )
end

function Kolor.addColors( struct, params )
	assert( type(struct)=='table' )
	params = params or {}
	if params.format==nil then params.format=Kolor._DEFAULT_FORMAT end
	--==--
	local c, a = Kolor._getTranslateFunctions( params.format )
	Kolor._NAMED_COLORS = Kolor._NAMED_COLORS or {}
	local ok, err = pcall( Kolor._processColors, Kolor._NAMED_COLORS, struct, c, a )
	if not ok then error( err, 2 ) end
end

-- returns a copy of the named color, or nil
--
function Kolor.getNamedColor( name )
	assert( type(name)=='string' )
	--==--
	assert( type(Kolor._NAMED_COLORS)=='table', "Kolor:getNamedColor there are no named colors loaded" )
	local color = Kolor._NAMED_COLORS[ slower( name ) ]
	return color and copyColor( color )
end



--====================================================================--
--== Private Functions


function Kolor._getTranslateFunctions( format )
	local known = false
	for _, f in ipairs( Kolor._VALID_FORMATS ) do
		if f==format then known = true end
	end
	assert( known, sfmt( "Kolor.setColorFormat unknown color format '%s'", tostr(format) ))
	--==--
	local c, a
	if Kolor.isTesting then
		c = RGBToTest
		a = dAToTest
	elseif format == Kolor.dRGBA then
		a = dAToHDR
		c = makeRGBToHDR( 1, a )
	elseif format==Kolor.hRGBA then
		a = hAToHDR
		c = makeRGBToHDR( 255, a )
	else -- hRGBdA
		a = dAToHDR
		c = makeRGBToHDR( 255, a )
	end
	return c, a
end

-- param c_tbl, array of color values, not changed
-- returns a new table; raises an error with no position
--
function Kolor._translateColor( c_tbl )
	-- print( "Kolor._translateColor" )
	local color, tmp
	local arg1 = c_tbl[1]
	local arg1Type = type(arg1)

	if arg1Type=='number' then
		-- regular RGB
		color = Kolor._COLOR_FUNC( c_tbl )

	elseif arg1Type=='table' and arg1.type=='gradient' then
		-- gradient RGB, translated into a copy
		color = {}
		for k, v in pairs( arg1 ) do color[ k ] = v end
		for _, key in ipairs{ 'color1', 'color2' } do
			tmp = color[ key ]
			if type(tmp)=='table' and tmp.type==nil then
				color[ key ] = Kolor._translateColor( tmp )
			elseif tmp~=nil then
				color[ key ] = Kolor._translateColor( { tmp } )
			end
		end

	elseif arg1Type=='table' and arg1.type~=nil then
		-- another paint, such as an image fill
		color = arg1

	elseif arg1Type=='string' and arg1:sub(1,1)=='#' then
		-- hex string
		color = HexToHDR( arg1, c_tbl[2], Kolor._ALPHA_FUNC )

	elseif arg1Type=='string' then
		-- named color
		check( Kolor._NAMED_COLORS~=nil,
			"unknown color name '%s': no named colors are loaded (NAMED_COLOR_FILE in dmc_corona.cfg)", arg1 )
		color = Kolor.getNamedColor( arg1 )
		check( color~=nil, "unknown color name '%s'", arg1 )
		if c_tbl[2]~=nil then color[4] = Kolor._ALPHA_FUNC( c_tbl[2] ) end

	else
		check( false, "unknown RGB color type '%s'", arg1Type )
	end

	return color
end



-- _processColors()
-- loop through key/value in table
-- translate color, put in color table
--
function Kolor._processColors( tbl, data, color_f, alpha_f )

	-- string or table
	local function translateColor( name, value )
		local val_type = type(value)

		if val_type=='table' then
			return color_f( value )
		elseif val_type=='string' and value:sub(1,1)=='#' then
			return HexToHDR( value, nil, alpha_f )
		else
			check( false, "color '%s' must be a hex string or a table, got '%s'", tostr(name), val_type )
		end
	end

	for name, value in pairs( data ) do
		-- print( name, value )
		tbl[ slower( name ) ] = translateColor( name, value )
	end
end



--====================================================================--
--== Kolor Setup
--====================================================================--


initialize()


return Kolor

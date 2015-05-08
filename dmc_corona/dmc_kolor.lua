--====================================================================--
-- dmc_kolor.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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
--== DMC Corona Library : DMC Kozy
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.0.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Support Functions


local Utils = {} -- make copying from lua_utils easier

function Utils.extend( fromTable, toTable )

	local function _extend( fT, tT )

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


function Utils.propertyIn( list, property )
	for i = 1, #list do
		if list[i] == property then return true end
	end
	return false
end



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

local dmc_kolor_data = Utils.extend( dmc_lib_data.dmc_kolor, DMC_KOLOR_DEFAULTS )



--====================================================================--
--== Imports


-- none



--====================================================================--
--== Setup, Constants


local sfmt = string.format
local tconcat = table.concat

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


--== Test Functions

local function dAToTest( value )
	return value
end

local function RGBToTest( value )
	return value
end


--== Decimal Alpha to HDR

local function dAToHDR( value )
	assert( value>=0 and value<=1, "incorrect range for alpha" )
	return value
end


--== Hex Alpha to HDR

local function hAToHDR( value )
	assert( value>=0 and value<=255, "incorrect range for alpha" )
	return value/255
end


--== Decimal RGB to HDR

local function dRGBToHDR( c_tbl )
	assert( c_tbl[1]>=0 and c_tbl[1]<=1, "incorrect value for color component" )
	assert( c_tbl[2]>=0 and c_tbl[2]<=1, "incorrect value for color component" )
	assert( c_tbl[3]>=0 and c_tbl[3]<=1, "incorrect value for color component" )
	if c_tbl[4] then
		assert( c_tbl[4]>=0 and c_tbl[4]<=1, "incorrect range for alpha" )
	end
	return c_tbl
end


--== Hex RGB to HDR

-- translate 255 to 1.0
local function hRGBToHDR( c_tbl )
	-- print( "hRGBToHDR" )
	if c_tbl[2] == nil then
		-- greyscale
		c_tbl[2] = c_tbl[1]
		c_tbl[3] = c_tbl[1]
	elseif c_tbl[3] == nil then
		-- greyscale with alpha
		c_tbl[2] = c_tbl[1]
		c_tbl[3] = c_tbl[1]
		c_tbl[4] = Kolor.translateAlpha( c_tbl[2] )
	elseif c_tbl[4] == nil then
		-- RGB, no alpha
	else
		-- RGB, with alpha
		c_tbl[4] = Kolor.translateAlpha( c_tbl[4] )
	end

	return { c_tbl[1]/255, c_tbl[2]/255, c_tbl[3]/255, c_tbl[4] }
end


--== Hex String to HDR

-- #FF00FF to { 1, 0, 1 }
local function HexToHDR( hex, alpha )
	-- print( "HexToHDR", hex, alpha )
	local value = hex:gsub("#","")
	return {
		tonumber( "0x"..value:sub(1,2) ) / 255,
		tonumber( "0x"..value:sub(3,4) ) / 255,
		tonumber( "0x"..value:sub(5,6) ) / 255,
		Kolor.translateAlpha( alpha )
	}
end




--====================================================================--
--== Kolor Setup
--====================================================================--


Kolor = {}

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
Kolor.isTesting = Kolor._RUN_MODE=='run'


--====================================================================--
--== Public Functions


--== Initialize Kolor Set

function Kolor.initializeKolorSet( func, mode )
	-- print( "Kolor.initializeKolorSet", mode )
	assert( func, "Kolor.initializeKolorSet requires function" )
	mode = mode or Kolor.dRGBA
	--==--
	local format = Kolor.getColorFormat()
	Kolor.setColorFormat( mode )
	func()
	Kolor.setColorFormat( format )
end

function Kolor.setRunMode( mode )
	Kolor._RUN_MODE = mode
	Kolor.isTesting = ( Kolor._RUN_MODE=='run' )
end


--== Color Format

function Kolor.getColorFormat()
	return Kolor._FORMAT
end

function Kolor.setColorFormat( value )
	-- print( "Kolor.setColorFormat", value )
	assert( type(value)=='string', sfmt( "Kolor.setColorFormat, expected type 'string', got '%s'", tostring(type(value)) ))
	--==--
	local c, a = Kolor._getTranslateFunctions( value )

	Kolor._FORMAT = value
	Kolor._COLOR_FUNC = c
	Kolor._ALPHA_FUNC = a
end


--== Color Translation

-- colors ( 5,5,5,5 )
function Kolor.translateColor(...)
	local args = {...}
	local arg1 = args[1]
	local arg1Type = type(arg1)

	if arg1Type=='nil' then
		return nil
	elseif arg1Type=='table' and arg1.type==nil then
		-- not gradient
		return Kolor._translateColor( arg1 )
	else
		return Kolor._translateColor( args )
	end
end

function Kolor.translateAlpha( alpha )
	if not alpha then return alpha end
	return Kolor._ALPHA_FUNC( alpha )
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
	Kolor._processColors( Kolor._NAMED_COLORS, struct, c, a )
end

function Kolor.getNamedColor( name )
	assert( type(name)=='string' )
	--==--
	assert( type(Kolor._NAMED_COLORS)=='table', "Kolor:getNamedColor there are no named colors loaded" )
	local key = string.lower( name )
	return Kolor._NAMED_COLORS[ key ]
end



--====================================================================--
--== Private Functions


function Kolor._getTranslateFunctions( format )
	assert( Utils.propertyIn( Kolor._VALID_FORMATS, format ), sfmt( "Kolor.setColorFormat unknown color format '%s'", tostring(format) ))
	--==--
	local c, a
	if Kolor.isTesting then
		c = RGBToTest
		a = dAToTest
	elseif format == Kolor.dRGBA then
		c = dRGBToHDR
		a = dAToHDR
	elseif format==Kolor.hRGBA then
		c = hRGBToHDR
		a = hAToHDR
	else -- hRGBdA
		c = hRGBToHDR
		a = dAToHDR
	end
	return c, a
end

-- param c_tbl, array of color values
--
function Kolor._translateColor( c_tbl )
	-- print( "Kolor._translateColor" )
	local tstr = tostring
	local color, tmp, key
	local arg1 = c_tbl[1]
	local arg1Type = type(arg1)

	-- print( unpack( c_tbl ) )

	if arg1Type=='number' then
		-- regular RGB
		color = Kolor._COLOR_FUNC( c_tbl )

	elseif arg1Type=='table' and arg1.type=='gradient' then
		-- gradient RGB
		tmp = arg1
		tmp.color1 = Kolor.translateColor( tmp.color1 )
		tmp.color2 = Kolor.translateColor( tmp.color2 )
		color = tmp

	elseif arg1Type=='string' and arg1:sub(1,1)=='#' then
		-- hex string
		color = HexToHDR( arg1, c_tbl[2] )

	elseif arg1Type=='string' then
		-- named color
		color = Kolor.getNamedColor( arg1 )

	else
		error( sfmt("ERROR dmc-kolor: unknown RGB color type '%s'", type( arg1 ) ))
	end

	-- print( unpack( color ) )

	return color
end



-- _processColors()
-- loop through key/value in table
-- translate color, put in color table
--
function Kolor._processColors( tbl, data, color_f, alpha_f )

	-- string or table
	local function translateColor( value )
		local val_type = type(value)

		if val_type=='table' then
			color = color_f( value )
		elseif val_type=='string' and value:sub(1,1)=='#' then
			color = HexToHDR( value )
		else
			error( sfmt("ERROR dmc_kolor: unknown RGB color type '%s'", type( value ) ))
		end

		return color
	end

	local slower = string.lower
	for name, value in pairs( data ) do
		-- print( name, value )
		local key = slower( name )
		tbl[ key ] = translateColor( value )
	end
end



--====================================================================--
--== Kolor Setup
--====================================================================--


initialize()


return Kolor

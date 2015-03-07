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

local function dRGBToHDR( ... )
	local args = {...}
	assert( args[1]>=0 and args[1]<=1 )
	assert( args[2]>=0 and args[2]<=1 )
	assert( args[3]>=0 and args[3]<=1 )
	if args[4] then
		assert( args[4]>=0 and args[4]<=1, "incorrect range for alpha" )
	end
	return {...}
end


--== Hex RGB to HDR

-- translate 255 to 1.0
local function hRGBToHDR( ... )
	-- print( "hRGBToHDR" )
	local args = { ... }

	if args[2] == nil then
		-- greyscale
		args[2] = args[1]
		args[3] = args[1]
	elseif args[3] == nil then
		-- greyscale with alpha
		args[2] = args[1]
		args[3] = args[1]
		args[4] = Kolor.translateAlpha( args[2] )
	elseif args[4] == nil then
		-- RGB, no alpha
	else
		-- RGB, with alpha
		args[4] = Kolor.translateAlpha( args[4] )
	end

	return { args[1]/255, args[2]/255, args[3]/255, args[4] }
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

Kolor._NAMED_COLORS = {}

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



--====================================================================--
--== Public Functions


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


function Kolor.translateColor(...)
	local args = {...}
	local tstr = tostring
	local color, tmp, key
	local arg1 = args[1]

	if type( arg1 )=='number' then
		-- regular RGB
		color = Kolor._COLOR_FUNC(...)

	elseif type( arg1 )=='table' and arg1.type=='gradient' then
		-- gradient RGB
		tmp = arg1
		tmp.color1 = Kolor._COLOR_FUNC( tmp.color1 )
		tmp.color2 = Kolor._COLOR_FUNC( tmp.color2 )
		color = tmp

	elseif type( arg1 ) == 'string' and arg1:sub(1,1)=='#' then
		-- hex string
		color = HexToHDR( arg1, args[2] )

	elseif type( arg1 ) == 'string' then
		-- named color
		Kolor.getNamedColor( arg1 )

	else
		error( sfmt("ERROR dmc_kolor: unknown RGB color type '%s'", type( arg1 ) ))
	end

	return color
end

function Kolor.translateAlpha( alpha )
	if not alpha then return alpha end
	return Kolor._ALPHA_FUNC( alpha )
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
	Kolor._processColors( Kolor._NAMED_COLORS, struct, c, a )
end

function Kolor.getNamedColor( name )
	assert( type(name)=='string' )
	--==--
	return Kolor._NAMED_COLORS[ name ]
end



--====================================================================--
--== Private Functions


function Kolor._getTranslateFunctions( format )
	assert( Utils.propertyIn( Kolor._VALID_FORMATS, format ), sfmt( "Kolor.setColorFormat unknown color format '%s'", tostring(format) ))
	--==--
	local c, a
	if format == Kolor.dRGBA then
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


-- _processColors()
-- loop through key/value in table
-- translate color, put in color table
--
function Kolor._processColors( tbl, data, color_f, alpha_f )

	local function translateColor(...)
		local args = {...}
		local color

		if type( args[1] )=='table' then
			color = color_f( unpack( args[1] ) )
		elseif type( args[1] ) == 'string' and args[1]:sub(1,1)=='#' then
			color = HexToHDR( args[1], args[2] )
		else
			error( sfmt("ERROR dmc_kolor: unknown RGB color type '%s'", type( args[1] ) ))
		end

		return color
	end

	for name, color in pairs( data ) do
		-- print( name, color )
		tbl[name] = translateColor( color )
	end
end



--====================================================================--
--== Kolor Setup
--====================================================================--


initialize()


return Kolor

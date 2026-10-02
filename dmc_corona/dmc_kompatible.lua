--====================================================================--
-- dmc_corona/dmc_kompatible.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-kompatible
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
-- DMC Corona Library : DMC Kompatible
--====================================================================--

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.0"



--====================================================================--
-- Configuration

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
-- DMC Kompatible
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_kompatible = dmc_lib_data.dmc_kompatible or {}

local DMC_KOMPATIBLE_DEFAULTS = {
	make_global=false,
	print_warnings=true,

	-- G1 deprecated methods
	activate_reference=true,
	activate_fillcolor=true,
	activate_strokecolor=true,
}

-- toBool()
-- config values come as booleans (with the :BOOL type) or as
-- strings (without it); anything but false (or 'false') is on
--
local function toBool( v )
	return v ~= false and v ~= 'false'
end

local dmc_kompatible_data = {}
for k, default in pairs( DMC_KOMPATIBLE_DEFAULTS ) do
	local v = dmc_lib_data.dmc_kompatible[ k ]
	if v == nil then v = default end
	dmc_kompatible_data[ k ] = toBool( v )
end


--====================================================================--
-- Setup, Constants

-- reference to the native object
local _DISPLAY = _G.display
local _NATIVE = _G.native

local dkd = dmc_kompatible_data -- make shorter reference

local Display, Native

-- the nine Graphics 1.0 reference points, with their anchors
local REFERENCE_POINTS = {
	TopLeft={ 0, 0 },
	TopCenter={ 0.5, 0 },
	TopRight={ 1, 0 },
	CenterLeft={ 0, 0.5 },
	Center={ 0.5, 0.5 },
	CenterRight={ 1, 0.5 },
	BottomLeft={ 0, 1 },
	BottomCenter={ 0.5, 1 },
	BottomRight={ 1, 1 },
}

-- Solar2D's own reference point constants (userdata), to anchors
local SOLAR2D_POINTS = {}

for name, anchor in pairs( REFERENCE_POINTS ) do
	local point = _DISPLAY[ name..'ReferencePoint' ]
	if point ~= nil then SOLAR2D_POINTS[ point ] = anchor end
end

local line_warned = false -- the newLine() warning is printed once


--====================================================================--
-- Support Methods

-- translateGradientColor()
-- a gradient's color table, { r, g, b [, a] } in 0-255, to a new
-- table in Solar2D's 0-1 values; nil and a message if it isn't one
--
local function translateGradientColor( t, name )
	if type( t ) ~= 'table' or type( t[1] ) ~= 'number'
		or type( t[2] ) ~= 'number' or type( t[3] ) ~= 'number' then
		return nil, "gradient "..name.." must be { r, g, b [, a] }"
	end
	return { t[1]/255, t[2]/255, t[3]/255, ( t[4] or 255 )/255 }
end


-- translateRGBToHDR()
-- translates a Graphics 1.0 color (0-255, hex string, gradient)
-- to the arguments for Solar2D's own method, in a list;
-- nil and a message if it isn't a color
--
local function translateRGBToHDR( ... )
	local args = { ... }
	local n = select( '#', ... )
	while n > 0 and args[ n ] == nil do n = n-1 end
	local c = args[1]

	if type( c ) == 'number' then
		for i=1,n do
			if type( args[i] ) ~= 'number' then
				return nil, "invalid color: argument "..i.." is a "..type( args[i] )
			end
		end
		if n == 1 then
			-- greyscale
			return { c/255, c/255, c/255, 1 }
		elseif n == 2 then
			-- greyscale with alpha
			return { c/255, c/255, c/255, args[2]/255 }
		elseif n == 3 or n == 4 then
			-- RGB, RGBA
			return { c/255, args[2]/255, args[3]/255, ( args[4] or 255 )/255 }
		end
		return nil, "invalid color: "..n.." numbers"

	elseif type( c ) == 'string' then
		local hex = c:match( '^#(%x%x%x%x%x%x)$' )
		if not hex then
			return nil, "invalid color '"..c.."': use '#RRGGBB' (dmc-kolor has color names)"
		end
		return {
			tonumber( hex:sub(1,2), 16 )/255,
			tonumber( hex:sub(3,4), 16 )/255,
			tonumber( hex:sub(5,6), 16 )/255
		}

	elseif type( c ) == 'table' and c.type == 'gradient' then
		-- translate a copy: the caller's table may be used again
		local gradient, err = {}
		for k, v in pairs( c ) do gradient[ k ] = v end
		gradient.color1, err = translateGradientColor( c.color1, 'color1' )
		if not gradient.color1 then return nil, err end
		gradient.color2, err = translateGradientColor( c.color2, 'color2' )
		if not gradient.color2 then return nil, err end
		return { gradient }

	elseif type( c ) == 'table' then
		-- another paint (image, composite): Solar2D's own
		return { c }
	end

	return nil, "invalid color type "..type( c )
end


-- addColorMethod()
-- add method name to the object, taking Graphics 1.0 colors and
-- calling Solar2D's own method; Solar2D's is kept as _<own>
-- (two names can share one: text's setFillColor and setTextColor)
-- rawset: Solar2D ignores setting a line's color methods the usual way
--
local function addColorMethod( o, name, own )
	own = own or name
	local original = o[ '_'..own ] or o[ own ]
	rawset( o, '_'..own, original ) -- save original version
	rawset( o, name, function( _, ... )
		local color, err = translateRGBToHDR( ... )
		if not color then error( "dmc_kompatible: "..err, 2 ) end
		return original( o, unpack( color ) )
	end )
end


-- addSetAnchor()
-- imbue object with setReferencePoint magic
--
local function addSetAnchor( o, reference )

	o.setReferencePoint = function( _, x, y )
		local anchor = SOLAR2D_POINTS[ x ] or x
		if type( anchor ) == 'table' then
			x, y = anchor[1], anchor[2]
		end
		local valid = ( x ~= nil or y ~= nil )
			and ( x == nil or type( x ) == 'number' )
			and ( y == nil or type( y ) == 'number' )
		if not valid then
			error( "dmc_kompatible: setReferencePoint() takes a reference point, such as display.CenterReferencePoint, or numbers; got "..tostring( x ), 2 )
		end
		-- a missing value keeps the current one (nil crashes Solar2D)
		o.anchorX = x or o.anchorX
		o.anchorY = y or o.anchorY
	end

	if reference then
		o:setReferencePoint( reference )
	end
end


-- imbue()
-- add the methods listed in adds to the new object, as configured;
-- nil (Solar2D's answer for a missing file) is passed on
--
local function imbue( o, adds )
	if o == nil then return nil end

	if dkd.activate_reference then
		addSetAnchor( o, adds.reference )
	end
	if dkd.activate_fillcolor then
		for name, own in pairs( adds.fill or {} ) do addColorMethod( o, name, own ) end
	end
	if dkd.activate_strokecolor and adds.stroke then
		addColorMethod( o, 'setStrokeColor' )
	end

	return o
end


-- wrapConstructors()
-- add each constructor in list to lib, calling Solar2D's own in super
--
local function wrapConstructors( lib, super, list )
	for name, adds in pairs( list ) do
		lib[ name ] = function( ... )
			return imbue( super[ name ]( ... ), adds )
		end
	end
end



--====================================================================--
-- Display Class Setup
--====================================================================--

Display = {}
Display.NAME = "DMC_KOMPATIBLE DISPLAY"

Display.super = _DISPLAY
setmetatable( Display, { __index=Display.super } )


--== Config ==--

for name, anchor in pairs( REFERENCE_POINTS ) do
	Display[ name..'ReferencePoint' ] = anchor
end


--== Corona Display API ==--

local CENTER = Display.CenterReferencePoint
local TOP_LEFT = Display.TopLeftReferencePoint

-- fill: method name = Solar2D's method it calls
local FILL = { setFillColor='setFillColor' }

wrapConstructors( Display, _DISPLAY, {
	newCircle={ reference=CENTER, fill=FILL, stroke=true },
	newContainer={},
	newGroup={},
	newImage={ reference=TOP_LEFT, fill=FILL },
	newImageRect={ reference=TOP_LEFT, fill=FILL },
	-- a line is colored by its stroke; Graphics 1.0's line:setColor()
	newLine={ reference=TOP_LEFT, fill={ setColor='setStrokeColor' }, stroke=true },
	newPolygon={ reference=TOP_LEFT, fill=FILL, stroke=true },
	newRect={ reference=CENTER, fill=FILL, stroke=true },
	newRoundedRect={ reference=CENTER, fill=FILL, stroke=true },
	newSprite={},
	-- Graphics 1.0's text:setTextColor()
	newText={ reference=CENTER,
		fill={ setFillColor='setFillColor', setTextColor='setFillColor' } },
})

-- Graphics 1.0 lines had width, now strokeWidth
local newLine = Display.newLine

function Display.newLine( ... )
	if dkd.print_warnings and not line_warned then
		line_warned = true
		print( "WARNING dmc_kompatible: change newLine property 'width' to 'strokeWidth'" )
	end
	return newLine( ... )
end



--====================================================================--
-- Native Class Setup
--====================================================================--

Native = {}
Native.NAME = "DMC_KOMPATIBLE NATIVE"

Native.super = _NATIVE
setmetatable( Native, { __index=Native.super } )


--== Corona Native API ==--

-- text fields and boxes color their text with setTextColor(),
-- 0-255 like Graphics 1.0; web views have no color
local TEXT = { setTextColor='setTextColor' }

wrapConstructors( Native, _NATIVE, {
	newTextBox={ reference=TOP_LEFT, fill=TEXT },
	newTextField={ reference=TOP_LEFT, fill=TEXT },
	newWebView={ reference=TOP_LEFT },
})



--====================================================================--
-- Final Setup
--====================================================================--


--== Make Global

if dkd.make_global then
	_G.display = Display
	_G.native = Native
end


-- call the module to get the two tables:
-- local display, native = require( 'dmc_corona.dmc_kompatible' )()
return setmetatable( { VERSION=VERSION, display=Display, native=Native }, {
	__call=function() return Display, Native end
})

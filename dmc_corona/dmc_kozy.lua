--====================================================================--
-- dmc_kozy.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-kozy
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

local VERSION = "1.1.1"



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
--== DMC Kozy
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_kozy = dmc_lib_data.dmc_kozy or {}

local DMC_KOZY_DEFAULTS = {
	make_global=false,

	-- G1 deprecated methods
	activate_zeroone_alpha=true,
	activate_anchor=true,
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

local dmc_kozy_data = {}
for k, default in pairs( DMC_KOZY_DEFAULTS ) do
	local v = dmc_lib_data.dmc_kozy[ k ]
	if v == nil then v = default end
	dmc_kozy_data[ k ] = toBool( v )
end



--====================================================================--
--== Setup, Constants


-- reference to the native object
local _DISPLAY = _G.display
local _NATIVE = _G.native

local dkd = dmc_kozy_data -- make shorter reference

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



--====================================================================--
--== Support Functions


-- translateAlpha()
-- an alpha in the configured range to Solar2D's 0-1
--
local function translateAlpha( a )
	if a == nil then return 1 end
	if dkd.activate_zeroone_alpha then return a end
	return a/255
end


-- translateGradientColor()
-- a gradient's color table, { r, g, b [, a] } in 0-255, to a new
-- table in Solar2D's 0-1 values; nil and a message if it isn't one
--
local function translateGradientColor( t, name )
	if type( t ) ~= 'table' or type( t[1] ) ~= 'number'
		or type( t[2] ) ~= 'number' or type( t[3] ) ~= 'number' then
		return nil, "gradient "..name.." must be { r, g, b [, a] }"
	end
	return { t[1]/255, t[2]/255, t[3]/255, translateAlpha( t[4] ) }
end


-- translateColor()
-- translates a Graphics 1.0 color (0-255, hex string, gradient)
-- to the arguments for Solar2D's own method, in a list;
-- nil and a message if it isn't a color
--
local function translateColor( ... )
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
			-- gray
			return { c/255, c/255, c/255, 1 }
		elseif n == 2 then
			-- gray with alpha
			return { c/255, c/255, c/255, translateAlpha( args[2] ) }
		elseif n == 3 or n == 4 then
			-- RGB, RGBA
			return { c/255, args[2]/255, args[3]/255, translateAlpha( args[4] ) }
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
-- replace the object's method with one taking Graphics 1.0 colors;
-- Solar2D's own is kept as _<name>
-- rawset: Solar2D ignores setting a line's color methods the usual way
--
local function addColorMethod( o, name )
	local original = o[ name ]
	rawset( o, '_'..name, original ) -- save original version
	rawset( o, name, function( _, ... )
		local color, err = translateColor( ... )
		if not color then error( "dmc_kozy: "..err, 2 ) end
		return original( o, unpack( color ) )
	end )
end


-- addSetAnchor()
-- imbue object with setAnchor / setReferencePoint magic
--
local function addSetAnchor( o )

	local function setAnchor( x, y )
		-- a missing value keeps the current one (nil crashes Solar2D)
		o.anchorX = x or o.anchorX
		o.anchorY = y or o.anchorY
	end

	o.setAnchor = function( _, x, y )
		if type( x ) == 'table' then x, y = x[1], x[2] end
		if x ~= nil and type( x ) ~= 'number' or y ~= nil and type( y ) ~= 'number' then
			error( "dmc_kozy: setAnchor() takes numbers or { x, y }", 2 )
		end
		setAnchor( x, y )
	end

	o.setReferencePoint = function( _, point )
		local anchor = SOLAR2D_POINTS[ point ] or point
		if type( anchor ) ~= 'table' or type( anchor[1] ) ~= 'number'
			or type( anchor[2] ) ~= 'number' then
			error( "dmc_kozy: setReferencePoint() takes a reference point, such as display.CenterReferencePoint; got "..tostring( point ), 2 )
		end
		setAnchor( anchor[1], anchor[2] )
	end
end


-- imbue()
-- add the methods listed in adds to the new object, as configured;
-- nil (Solar2D's answer for a missing file) is passed on
--
local function imbue( o, adds )
	if o == nil then return nil end

	if dkd.activate_anchor then
		addSetAnchor( o )
	end
	if dkd.activate_fillcolor then
		for _, name in ipairs( adds.fill or {} ) do addColorMethod( o, name ) end
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
--== Display Class Setup
--====================================================================--


Display = {}
Display.NAME = "DMC Kozy Display"

Display.super = _DISPLAY
setmetatable( Display, { __index=Display.super } )


--== Config ==--

for name, anchor in pairs( REFERENCE_POINTS ) do
	Display[ name..'ReferencePoint' ] = anchor
end


--== Corona Display API ==--

local FILL = { 'setFillColor' }

wrapConstructors( Display, _DISPLAY, {
	newCircle={ fill=FILL, stroke=true },
	newContainer={},
	newGroup={},
	newImage={ fill=FILL },
	newImageRect={ fill=FILL },
	newLine={ stroke=true },
	newPolygon={ fill=FILL, stroke=true },
	newRect={ fill=FILL, stroke=true },
	newRoundedRect={ fill=FILL, stroke=true },
	newSprite={},
	newText={ fill=FILL },
})



--====================================================================--
--== Native Class Setup
--====================================================================--


Native = {}
Native.NAME = "DMC Kozy Native"

Native.super = _NATIVE
setmetatable( Native, { __index=Native.super } )


--== Corona Native API ==--

-- text fields and boxes color their text with setTextColor(),
-- 0-255 like Graphics 1.0; web views have no color
local TEXT = { 'setTextColor' }

wrapConstructors( Native, _NATIVE, {
	newTextBox={ fill=TEXT },
	newTextField={ fill=TEXT },
	newWebView={},
})


function Native.setKeyboardFocus( obj )
	-- print( 'dmc_kozy.setKeyboardFocus', obj )

	if obj~=nil and obj.__is_dmc and obj.setKeyboardFocus then
		obj:setKeyboardFocus()
	else
		Native.super.setKeyboardFocus( obj )
	end
end




--====================================================================--
--== Final Setup
--====================================================================--


--== Make Global

if dkd.make_global then
	_G.display = Display
	_G.native = Native
end


-- call the module to get the two tables:
-- local display, native = require( 'dmc_corona.dmc_kozy' )()
return setmetatable( { VERSION=VERSION, display=Display, native=Native }, {
	__call=function() return Display, Native end
})

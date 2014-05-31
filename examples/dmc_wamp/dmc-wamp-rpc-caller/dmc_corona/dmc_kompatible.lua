--====================================================================--
-- dmc_kompatible.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_kompatible.lua
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

local VERSION = "1.1.0"



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
-- DMC Library : DMC Kompatible
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_kompatible = dmc_lib_data.dmc_kompatible or {}

local DMC_KOMPATIBLE_DEFAULTS = {
	make_global=false,
	print_warnings= true,

	-- G1 deprecated methods
	activate_reference=true,
	activate_fillcolor=true,
	activate_strokecolor=true,
}

local dmc_kompatible_data = Utils.extend( dmc_lib_data.dmc_kompatible, DMC_KOMPATIBLE_DEFAULTS )


--====================================================================--
-- Setup, Constants

-- reference to the native object
local _DISPLAY = _G.display
local _NATIVE = _G.native

local dkd = dmc_kompatible_data -- make shorter reference


local Display, Native


--====================================================================--
-- Support Methods

-- translateRGBToHDR()
-- translates RGB color sequence to equivalent HDR values
--
function translateRGBToHDR( ... )
	-- print( 'translateRGBToHDR' )

	local args = { ... }
	local color

	-- print(  args[1], args[2], args[3], args[4], args[5] )

	if type( args[2] ) == 'number' then
		-- regular RGB
		if args[3] == nil then
			-- greyscale
			args[3] = args[2]
			args[4] = args[2]
			args[5] = 255
		elseif args[4] == nil then
			-- greyscale with alpha
			args[3] = args[2]
			args[4] = args[2]
			args[5] = args[3]
		elseif args[5] == nil then
			-- RGB, no alpha
			args[5] = 255
		end

		color = { args[2]/255, args[3]/255, args[4]/255, args[5]/255 }

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



-- addSetAnchor()
-- imbue object with setReferencePoint magic
--
function addSetAnchor( o, reference  )
	-- print( 'addSetAnchor' )

	function createClosure( obj )
		local f = function( ... )
			local args = {...}
			local x, y

			if type( args[2] ) == 'table' then
				x, y = unpack( args[2] )
			end
			if type( args[2] ) == 'number' then
				x = args[2]
			end
			if type( args[3] ) == 'number' then
				y = args[3]
			end

			obj.anchorX = x
			obj.anchorY = y
		end
		return f
	end

	o.setReferencePoint = createClosure( o )
	if reference then
		o:setReferencePoint( reference )
	end

end



-- addSetFillColor()
-- imbue object with setFillColor / setTextColor magic
--
function addSetFillColor( o )
	-- print( 'addSetFillColor' )

	function createClosure( obj, translate )
		local f = function( ... )
			-- print( 'DMC Kompatible :DISPLAY COLOR\n')
			local args = { ... }
			-- print(  args[1], args[2], args[3], args[4] )
			local color = translate( ... )
			obj:_setFillColor( unpack( color ) )
		end
		return f
	end

	o._setFillColor = o.setFillColor -- save original version
	o.setFillColor = createClosure( o, translateRGBToHDR )

end



-- addSetStrokeColor()
-- imbue object with strokeColor magic
--
function addSetStrokeColor( o )
	-- print( 'addSetStrokeColor' )

	function createClosure( obj, translate )
		-- print('createClosure stroke')
		local f = function( ... )
			local color = translate( ... )
			obj:_setStrokeColor( unpack( color ) )
		end
		return f
	end

	o._setStrokeColor = o.setStrokeColor -- save original version
	o.setStrokeColor = createClosure( o, translateRGBToHDR )

end



--====================================================================--
-- Display Class Setup
--====================================================================--

Display = {}
Display.NAME = "DMC_KOMPATIBLE DISPLAY"

Display.super = _DISPLAY
setmetatable( Display, { __index=Display.super } )


--== Config ==--

Display.TopLeftReferencePoint = { 0, 0 }
Display.TopCenterReferencePoint = { 0.5, 0 }
Display.TopRightReferencePoint = { 1, 0 }
Display.CenterLeftReferencePoint = { 0, 0.5 }
Display.CenterReferencePoint = { 0.5, 0.5 }
Display.CenterRightReferencePoint = { 1, 0.5 }
Display.BottomLeftReferencePoint = { 0, 1 }
Display.BottomCenterReferencePoint = { 0.5, 1 }
Display.BottomRightReferencePoint = { 1, 1 }


--== Corona Display API ==--

function Display.newCircle( ... )
	-- print( 'Kompatible.newCircle' )

	local o = Display.super.newCircle( ... )
	local p

	if dkd.activate_reference then
		addSetAnchor( o, Display.CenterReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end
	if dkd.activate_strokecolor then
		addSetStrokeColor( o )
	end

	return o
end


function Display.newContainer( ... )
	-- print( 'Kompatible.newContainer' )

	local o = Display.super.newContainer( ... )

	if dkd.activate_reference then
		-- addSetAnchor( o, Display.TopLeftReferencePoint )
		addSetAnchor( o )
	end

	return o
end


function Display.newGroup( ... )
	-- print( 'Kompatible.newGroup' )

	local o = Display.super.newGroup( ... )

	if dkd.activate_reference then
		-- addSetAnchor( o, Display.TopLeftReferencePoint )
		addSetAnchor( o )
	end

	return o
end


function Display.newImage( ... )
	-- print( 'Kompatible.newImage' )

	local o = Display.super.newImage( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end

	return o
end


function Display.newImageRect( ... )
	-- print( 'Kompatible.newImageRect' )

	local o = Display.super.newImageRect( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end

	return o
end





function Display.newLine( ... )
	-- print( 'Kompatible.newLine' )

	local o = Display.super.newLine( ... )

	if dkd.print_warnings then
		print('\n')
		print( "WARNING KOMPATIBLE: change newLine property 'width' to 'strokeWidth'" )
		print('\n')
	end
	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
		o.setColor = o.setFillColor
	end

	return o
end


function Display.newPolygon( ... )
	-- print( 'Kompat.newPolygon' )

	local o = Display.super.newPolygon( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetStrokeColor( o )
	end

	return o
end


function Display.newRect( ... )
	-- print( 'Kompatible.newRect' )

	local o = Display.super.newRect( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.CenterReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end
	if dkd.activate_strokecolor then
		addSetStrokeColor( o )
	end

	return o
end


function Display.newRoundedRect( ... )
	-- print( 'Kompatible.newRoundedRect' )

	local o = Display.super.newRoundedRect( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.CenterReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end
	if dkd.activate_strokecolor then
		addSetStrokeColor( o )
	end

	return o
end


function Display.newSprite( ... )
	-- print( 'Kompatible.newSprite' )

	local o = Display.super.newSprite( ... )

	if dkd.activate_reference then
		addSetAnchor( o )
	end

	return o
end


function Display.newText( ... )
	-- print( 'Kompatible.newText' )

	local o = Display.super.newText( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.CenterReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
		o.setTextColor = o.setFillColor
	end

	return o
end



--====================================================================--
-- Native Class Setup
--====================================================================--

Native = {}
Native.NAME = "DMC_KOMPATIBLE NATIVE"

Native.super = _NATIVE
setmetatable( Native, { __index=Native.super } )


--== Corona Native API ==--

function Native.newText( ... )
	-- print( 'Kompatible native.newText' )

	local o = Native.super.newText( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end

	return o
end


function Native.newTextBox( ... )
	-- print( 'Kompatible native.newTextBox' )

	local o = Native.super.newTextBox( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end

	return o
end


function Native.newTextField( ... )
	-- print( 'Kompatible native.newTextField' )

	local o = Native.super.newTextField( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end

	return o
end


function Native.newWebView( ... )
	-- print( 'Kompatible native.newWebView' )

	local o = Native.super.newWebView( ... )

	if dkd.activate_reference then
		addSetAnchor( o, Display.TopLeftReferencePoint )
	end
	if dkd.activate_fillcolor then
		addSetFillColor( o )
	end

	return o
end



--====================================================================--
-- Final Setup
--====================================================================--


--== Make Global

if dkd.make_global then
	_G.display = Display
	_G.native = Native
end


-- return function so we can return two values
return function() return Display, Native end

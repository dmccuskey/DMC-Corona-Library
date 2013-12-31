--====================================================================--
-- dmc_display.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_display.lua
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

local VERSION = "1.0.0"



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

dmc_lib_data.dmc_display = dmc_lib_data.dmc_display or {}

local DMC_DISPLAY_DEFAULTS = {
	-- none
	activate_anchor=true,
	activate_color=false
}

local dmc_display_data = Utils.extend( dmc_lib_data.dmc_display, DMC_DISPLAY_DEFAULTS )



--====================================================================--
-- Imports
--====================================================================--



--====================================================================--
-- Setup, Constants
--====================================================================--

-- reference to the original display object
local _DISPLAY = _G.display



--====================================================================--
-- Support Methods
--====================================================================--



--====================================================================--
-- Display Class Setup
--====================================================================--

local Display = {}


--== Setup ==--

-- so dmc_display works with dmc_kolor

if _G._dmc_setmt then
	_G._dmc_setmt( Display )
else
	Display.super = _DISPLAY
	setmetatable( Display, { __index=Display.super } )
end

_G._dmc_setmt = function( obj )
	obj.super = Display.super
	setmetatable( obj, { __index=obj.super } )

	Display.super = obj
	setmetatable( Display, { __index=Display.super } )
end


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


-- imbue object with fillColor magic
--
function Display._addSetAnchor( o )
	-- print( 'Kompatible._addSetAnchor' )

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
				y = args[2]
			end
			obj.anchorX = x
			obj.anchorY = y
		end
		return f
	end

	o.setAnchor = createClosure( o )
end



--== Corona Display API ==--


function Display.newCircle( ... )
	-- print( 'Kompatible.newCircle' )

	local o = Display.super.newCircle( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end


function Display.newImage( ... )
	-- print( 'Kompatible.newImage' )

	local o = Display.super.newImage( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end


function Display.newImageRect( ... )
	-- print( 'Kompatible.newImageRect' )

	local o = Display.super.newImageRect( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end


function Display.newLine( ... )
	-- print( 'Kompatible.newLine' )

	local o = Display.super.newLine( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end


function Display.newPolygon( ... )
	-- print( 'Kompat.newPolygon' )

	local o = Display.super.newPolygon( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end


function Display.newRect( ... )
	-- print( 'Kompatible.newRect' )

	-- local args = { ... }
	-- print(  args[1], args[2], args[3], args[4] )

	local o = Display.super.newRect( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end


function Display.newRoundedRect( ... )
	-- print( 'Kompatible.newRoundedRect' )

	local o = Display.super.newRoundedRect( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end


function Display.newText( ... )
	-- print( 'Kompatible.newText' )

	local o = Display.super.newText( ... )

	if dmc_display_data.activate_anchor then
		Display._addSetAnchor( o )
	end

	return o
end



--====================================================================--
-- Final Setup
--====================================================================--

if not _G.__dmc_display then _G.__dmc_display = Display end

return _G.__dmc_display

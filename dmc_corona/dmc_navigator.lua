--====================================================================--
-- dmc_navigator.lua
--
-- Documentation:
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
--== DMC Corona Library : DMC Navigator
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.3.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Support Functions


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
--== DMC Navigator
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_navigator = dmc_lib_data.dmc_navigator or {}

local DMC_NAVIGATOR_DEFAULTS = {
	debug_active=false
}

local dmc_navigator_data = Utils.extend( dmc_lib_data.dmc_navigator, DMC_NAVIGATOR_DEFAULTS )
local Config = dmc_navigator_data



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
-- local Utils = require 'dmc_utils'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local ComponentBase = Objects.ComponentBase

local tinsert = table.insert
local tremove = table.remove



--====================================================================--
--== View Navigation Class
--====================================================================--


local Navigator = newClass( ComponentBase, {name="DMC Navigator"} )

--== Class Constants

Navigator.TRANSITION_TIME = 400

Navigator.FORWARD = 'forward-direction'
Navigator.REVERSE = 'reverse-direction'

--== Event Constants

Navigator.EVENT = 'dmc-navigator-event'

Navigator.REMOVED_VIEW = 'removed-view-event'


--======================================================--
-- Start: Setup DMC Objects

function Navigator:__init__( params )
	-- print( "Navigator:__init__" )
	params = params or {}
	if params.transition_time==nil then params.transition_time=Navigator.TRANSITION_TIME end
	self:superCall( '__init__', params )
	--==--

	--== Sanity Check ==--

	if self.is_class then return end

	assert( params.width and params.height, "ERROR DMC Navigator: requires dimensions")

	--== Create Properties ==--

	self._width = params.width
	self._height = params.height

	self._trans_time = params.transition_time
	self._btn_back_f = nil
	self._enterFrame_f = nil

	self._views = {} -- slide list, in order

	--== Object References ==--

	self._root_view = nil
	self._back_view = nil
	self._top_view = nil
	self._new_view = nil
	self._visible_view = nil

	self._nav_bar = nil
	self._primer = nil

end

function Navigator:__undoInit__()
	--print( "Navigator:__undoInit__" )
	self._root_view = nil
	self._back_view = nil
	self._top_view = nil
	self._new_view = nil
	self._visible_view = nil
	--==--
	self:superCall( '__undoInit__' )
end


function Navigator:__createView__()
	-- print( "Navigator:__createView__" )
	self:superCall( '__createView__' )
	--==--

	local o, p, dg, tmp  -- object, display group, tmp

	--== Setup display primer

	o = display.newRect( 0, 0, self._width, self._height )
	o:setFillColor(0,0,0,0)
	if false or Config.debug_active then
		o:setFillColor(0.5,1,0.5)
	end
	o.anchorX, o.anchorY = 0.5, 0
	o.x, o.y = 0,0

	self:insert( o )
	self._primer = o

end
function Navigator:__undoCreateView__()
	-- print( "Navigator:__undoCreateView__" )

	local o

	o = self._primer
	o:removeSelf()
	self._primer = nil

	--==--
	self:superCall( '__undoCreateView__' )
end


-- __initComplete__()
--
function Navigator:__initComplete__()
	-- print( "Navigator:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	self._btn_back_f = self:createCallback( self._backButtonRelease_handler )
end

function Navigator:__undoInitComplete__()
	-- print( "Navigator:__undoInitComplete__" )
	local o

	self._btn_back_f = nil

	self:cleanUp()
	--==--
	self:superCall( '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function Navigator.__setters:nav_bar( value )
	-- print( "Navigator.__setters:nav_bar", value )
	-- TODO
	assert( value )
	self._nav_bar = value
end


function Navigator:cleanUp()
	-- print( "Navigator:cleanUp" )
	self:_stopEnterFrame()
	for i=#self._views, 1, -1 do
		local view = self:_popStackView()
		self:_removeViewFromNav( view )
	end
end


function Navigator:pushView( view, params )
	-- print( "Navigator:pushView" )
	params = params or {}
	assert( view, "[ERROR] Navigator:pushView requires a view object" )
	-- assert( type(item)=='table' and item.isa and item:isa( NavItem ), "pushNavItem: item must be a NavItem" )
	if params.animate==nil then params.animate=true end
	--==--

	if self._root_view then
		-- pass
	else
		self._root_view = view
		self._top_view = nil
		self._visible_view = nil
		params.animate = false
	end
	self._new_view = view

	self:_gotoNextView( params.animate )
end


function Navigator:popViewAnimated()
	self:_gotoPrevView( true )
end



function Navigator:viewIsVisible( value )
	-- print( "Navigator:viewIsVisible" )
	local o = self._current_view
	if o and o.viewIsVisible then o:viewIsVisible( value ) end
end


function Navigator:viewIsVisible( value )
	-- print( "Navigator:viewIsVisible" )
	local o = self._current_view
	if o and o.viewIsVisible then o:viewIsVisible( value ) end
end

function Navigator:viewInMotion( value )
	-- print( "Navigator:viewInMotion" )
	local o = self._current_view
	if o and o.viewInMotion then o:viewInMotion( value ) end
end



--====================================================================--
--== Private Methods


function Navigator:_getPushNavBarTransition( view, params )
	-- print( "Navigator:_getPushNavBarTransition", view )
	params = params or {}
	local o, callback
	if self._nav_bar then
		o = view.nav_bar_item
		assert( o, "view doesn't have nav bar item" )
		o.back_button.onRelease = self._btn_back_f
		callback = self._nav_bar:_pushNavItemGetTransition( o, {} )
	end
	return callback
end

function Navigator:_getPopNavBarTransition()
	-- print( "Navigator:_getPopNavBarTransition" )
	params = params or {}
	return self._nav_bar:_popNavItemGetTransition( params )
end


function Navigator:_pushStackView( view )
	tinsert( self._views, view )
end

function Navigator:_popStackView( notify )
	return tremove( self._views )
end


function Navigator:_addViewToNav( view )
	-- print( "Navigator:_addViewToNav", view )
	local o = view
	if o.view then
		o = o.view
	elseif o.display then
		o = o.display
	end
	self:insert( o )
	view.isVisible=false
end

function Navigator:_removeViewFromNav( view )
	-- print( "Navigator:_removeViewFromNav", view )
	view.isVisible=false
	self:_dispatchRemovedView( view )
end



function Navigator:_startEnterFrame( func )
	self._enterFrame_f = func
	Runtime:addEventListener( 'enterFrame', func )
end

function Navigator:_stopEnterFrame()
	if not self._enterFrame_f then return end
	Runtime:removeEventListener( 'enterFrame', self._enterFrame_f )
end


function Navigator:_startReverse( func )
	local start_time = system.getTimer()
	local duration = self._trans_time
	local rev_f -- forward

	rev_f = function(e)
		local delta_t = e.time-start_time
		local perc = 100-(delta_t/duration*100)
		if perc <= 0 then
			perc = 0
			self:_stopEnterFrame()
		end
		func( perc )
	end
	self:_startEnterFrame( rev_f )
end

function Navigator:_startForward( func )
	local start_time = system.getTimer()
	local duration = self._trans_time
	local frw_f -- forward

	frw_f = function(e)
		local delta_t = e.time-start_time
		local perc = delta_t/duration*100
		if perc >= 100 then
			perc = 100
			self:_stopEnterFrame()
		end
		func( perc )
	end
	self:_startEnterFrame( frw_f )
end


-- can be retreived by another object (ie, NavBar)
function Navigator:_getNextTrans()
	return self:_getTransition( self._top_view, self._new_view, self.FORWARD )
end

function Navigator:_gotoNextView( animate )
	-- print( "Navigator:_gotoNextView", animate )
	local func = self:_getNextTrans()
	if not animate then
		func( 100 )
	else
		self:_startForward( func )
	end
end


-- can be retreived by another object (ie, NavBar)
function Navigator:_getPrevTrans()
	-- print( "Navigator:_getPrevTrans" )
	return self:_getTransition( self._back_view, self._top_view, self.REVERSE )
end

function Navigator:_gotoPrevView( animate )
	-- print( "Navigator:_gotoPrevView" )
	local func = self:_getPrevTrans()
	if not animate then
		func( 0 )
	else
		self:_startReverse( func )
	end
end


function Navigator:_getTransition( from_view, to_view, direction )
	-- print( "Navigator:_getTransition", from_view, to_view, direction )
	local W, H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5
	local MARGINS = self.MARGINS

	local callback, nav_callback
	local stack, stack_size, stack_offset

	-- calcs for showing left/back buttons
	stack_offset = 0
	if direction==self.FORWARD then
		self:_addViewToNav( to_view )
		nav_callback = self:_getPushNavBarTransition( to_view )
		stack_offset = 0
	else
		nav_callback = self:_getPopNavBarTransition()
		stack_offset = 1
	end

	stack, stack_size = self._views, #self._views

	callback = function( percent )
		-- print( ">>trans", percent )
		local dec_p = percent/100
		local FROM_X_OFF = H_CENTER/2*dec_p
		local TO_X_OFF = W*dec_p

		if nav_callback then nav_callback( percent ) end


		if percent==0 then
			--== edge of transition ==--

			--== Finish up

			if direction==self.REVERSE then
				local view = self:_popStackView()
				self:_removeViewFromNav( view )

				self._top_view = from_view
				self._new_view = nil
				self._back_view = stack[ #stack-1 ] -- get previous
			end

			if from_view then
				from_view.isVisible = true
				from_view.x = 0
			end

			if to_view then
				to_view.isVisible = false
			end



		elseif percent==100 then
			--== edge of transition ==--

			if to_view then
				to_view.isVisible = true
				to_view.x = 0
			end

			if from_view then
				from_view.isVisible = false
				from_view.x = 0-FROM_X_OFF
			end


			if direction==self.FORWARD then
				self._back_view = from_view
				self._new_view = nil
				self._top_view = to_view

				self:_pushStackView( to_view )
			end


		else
			--== middle of transition ==--

			if to_view then
				to_view.isVisible = true
				to_view.x = W-TO_X_OFF
			end

			if from_view then
				from_view.isVisible = true
				from_view.x = 0-FROM_X_OFF
			end

		end

	end

	return callback
end


-- TODO: add methods
--[[
local s2_a = function()
	if prev_view.viewInMotion then prev_view:viewInMotion( true ) end
	if prev_view.viewIsVisible then prev_view:viewIsVisible( true ) end
	if next_view.viewInMotion then next_view:viewInMotion( true ) end
	if next_view.viewIsVisible then next_view:viewIsVisible( false ) end
	s2_b()
end
--]]


function Navigator:_dispatchRemovedView( view )
	-- print( "Navigator:_dispatchRemovedView", view )
	self:dispatchEvent( self.REMOVED_VIEW, {view=view}, {merge=true} )
end



--====================================================================--
--== Event Handlers


function Navigator:_backButtonRelease_handler( event )
	-- print( "Navigator:_backButtonRelease_handler", event )
	self:popViewAnimated()
end




return Navigator

--====================================================================--
-- Touch Manager Basic
--
-- Shows simple use of the Touch Manager
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2012 David McCuskey. All Rights Reserved.
--====================================================================--


print("---------------------------------------------------")


--===================================================================--
-- Imports
--===================================================================--

local TouchMgr = require( "dmc_touchmanager" )


-- Tools and Debugging
--[[
local isSimulator = "simulator" == system.getInfo("environment")
if isSimulator then
	ultimote = require "Ultimote"
	ultimote.connect()
end
--]]


--===================================================================--
-- Setup, Constants
--===================================================================--

display.setStatusBar( display.HiddenStatusBar )


--===================================================================--
-- Main
--===================================================================--


-- createTouchPoint()
-- create display object used to represent a screen touch
--
-- @params color table with R,G,B values
-- @return instance of display object
--
function createTouchPoint( color )
	local o = display.newCircle( 0, 0, 40 )
	o:setFillColor( unpack( color ) )
	return o
end



--== Setup Object-type Handler ==--

function setup_object_example()

	-- setup display object
	local color = { 255, 255, 255 }
	local o = display.newRect( 0, 0, 300, 300 )
	o:setFillColor( unpack( color ) )
	o.alpha = 0.5
	o:setReferencePoint( display.CenterReferencePoint )
	o.x = 384 ; o.y = 275

	-- setup some vars used to track touches
	local tp
	o._touch_num = 0
	o.touches = {}


	-- setup our object-type event call
	--
	function o:touch( event )

		if event.phase == 'began' then

			TouchMgr:setFocus( self, event.id )

			self:setStrokeColor( 171, 171, 255 )
			self.strokeWidth = 10

			self._touch_num = self._touch_num + 1

			tp = createTouchPoint( color )
			tp.x = event.x ; tp.y = event.y
			self.touches[ event.id ] = tp


		elseif event.phase == 'moved' then

			tp = self.touches[ event.id ]
			if tp then
				tp.x = event.x ; tp.y = event.y
			end


		elseif ( event.phase == 'canceled' or event.phase == 'ended' ) then

			TouchMgr:unsetFocus( self, event.id )

			tp = self.touches[ event.id ]
			if tp then
				self._touch_num = self._touch_num - 1
				self.touches[ event.id ] = nil
				tp:removeSelf()
			end

			if self._touch_num == 0 then
				self:setStrokeColor( 0, 0, 0 )
				self.strokeWidth = 0
			end

		end

		return true
	end


	-- return reference back for Touch Manager initialization
	return o

end



--== Setup Function-type Handler ==--

function setup_function_example()

	-- setup display object
	local color = { 255, 0, 0 }
	local o = display.newRect( 0, 0, 300, 300 )
	o:setFillColor( unpack( color ) )
	o.alpha = 0.5
	o:setReferencePoint( display.CenterReferencePoint )
	o.x = 384 ; o.y = 725

	-- setup some vars used to track touches
	local tp
	o._touch_num = 0
	o.touches = {}


	-- setup our function-type event call
	--
	local handler = function( event )

		local target = event.target

		if event.phase == 'began' then

			TouchMgr:setFocus( target, event.id )

			target:setStrokeColor( 171, 171, 255 )
			target.strokeWidth = 10

			target._touch_num = target._touch_num + 1

			tp = createTouchPoint( color )
			tp.x = event.x ; tp.y = event.y
			target.touches[ event.id ] = tp


		elseif event.phase == 'moved' then

			tp = target.touches[ event.id ]
			if tp then
				tp.x = event.x ; tp.y = event.y
			end


		elseif ( event.phase == 'canceled' or event.phase == 'ended' ) then

			TouchMgr:unsetFocus( target, event.id )

			tp = target.touches[ event.id ]
			if tp then
				target._touch_num = target._touch_num - 1
				target.touches[ event.id ] = nil
				tp:removeSelf()
			end

			if target._touch_num == 0 then
				target:setStrokeColor( 0, 0, 0 )
				target.strokeWidth = 0
			end

		end

		return true 
	end


	-- return references back for Touch Manager initialization
	return o, handler

end



-- main()
--
local main = function()

	local o, h
	
	o = setup_object_example()

	-- register the object/ handler with the Touch Manager
	--
	TouchMgr:register( o )


	o, h = setup_function_example()

	-- register the object/ handler with the Touch Manager
	--
	TouchMgr:register( o, h )

end


-- let's get this party started !
--
main()




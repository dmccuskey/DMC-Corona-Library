
--====================================================================--
-- progress bar object library
--
-- part of AutoStore library Advanced Example 
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2013 David McCuskey. All Rights Reserved.
--====================================================================--



--====================================================================--
-- Imports and Setup
--====================================================================--



--====================================================================--
-- Progress Bar base class
--====================================================================--


local Progress = {}
local Progress_meta = {
	__index = Progress
}


--==  Class constants  ==--

Progress.STROKE_WIDTH = 1
Progress.STROKE_COLOR = { 255, 255, 255 }
Progress.FILL_COLOR = {
	orange = { 255, 175, 60 },
	red = { 255, 70, 70 }
}
Progress.CORNER_RADIUS = 2


--==  Class constructor  ==--

-- new()
--
-- @param data table: { x=60, y=10, width=400, height=8, color='orange' }
--
function Progress:new( data )
	--print( "Progress:new" )

	local o = {}
	setmetatable( o, Progress_meta )

	o._data = data

	o:_init()

	return o
end


--==  Class Methods: Private  ==--

-- _init()
--
-- one of the base methods to override for dmc_objects
-- put on our object properties
--
function Progress:_init()
	--print( "Progress:_init" )

	local d = self._data
	local o

	-- Create Properties --

	self._dg = display.newGroup()  -- container for our bars
	self._inner = nil  -- ref to inner bar, the "fill"
	self._outer = nil  -- ref to outer bar, the "shell"

	self._time_count = 0 -- amount of time alloted to go to 100%, in milliseconds
	self._time_start = 0 -- time that we started counting


	-- Create View --

	-- outer border
	o = display.newRoundedRect(0, 0, d.width, d.height, Progress.CORNER_RADIUS )
	o.strokeWidth = 1
	o:setStrokeColor( unpack( Progress.STROKE_COLOR ) )
	o:setFillColor( 0, 0, 0 )

	o.x = d.width/2 ; o.y = 0

	self._outer = o
	self._dg:insert( o )


	-- inner fill
	o = display.newRoundedRect(0, 0, d.width, d.height, Progress.CORNER_RADIUS )
	o:setFillColor( unpack( Progress.FILL_COLOR[ d.color ] ) )
	o.x = d.width ; o.y = 0

	self._inner = o
	self._dg:insert( o )


	-- init Complete --

	self:_setPercentComplete( 0 )
	self._dg.x = d.x ; self._dg.y = d.y

end


function Progress:_setPercentComplete( value )
	--print( "Progress:_setPercentComplete" )

	local d = self._data
	local width = d.width * ( value / 100 )

	if width == 0 then
		self._inner.isVisible = false
	else
		self._inner.isVisible = true
		self._inner.width = width
		self._inner.x = ( d.width / 2 ) - ( d.width - width ) / 2
	end

end



--==  Class Methods: Public  ==--

function Progress:start( time )
	--print( "Progress:start" )

	self:stop()

	self._time_count = time
	self._time_start = system.getTimer() 

	Runtime:addEventListener( 'enterFrame', self )

end

function Progress:stop()
	--print( "Progress:stop" )

	self._time_start = 0
	self:_setPercentComplete( 0 )

	Runtime:removeEventListener( 'enterFrame', self )

end

function Progress:enterFrame( e )
	--print( "Progress:enterFrame" )

	local diff = e.time - self._time_start

	self:_setPercentComplete( diff / self._time_count * 100 )
	if diff >= self._time_count then
		self:stop()
	end

end




--====================================================================--
-- The Progress Bar Factory
--====================================================================--

local ProgressFactory = {}

function ProgressFactory.create( data )
	return Progress:new( data )
end

return ProgressFactory




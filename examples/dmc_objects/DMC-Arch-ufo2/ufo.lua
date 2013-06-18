
--====================================================================--
-- Imports
--====================================================================--

local Objects = require( "dmc_objects" )


--====================================================================--
-- Module Setup, Constants, & Support
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase


local rand = math.random


local function getRandomNumber( lower, upper )
	return math.random( lower, upper )
end

-- calculate time for given distance and velocity
--
local function calculateTime( x1, y1, x2, y2, velocity )
	local distance, time

	-- calculate pythagorean
	distance = math.pow( (x1-x2), 2) + math.pow( (y1-y2), 2)
	distance = math.sqrt( distance )

	time = math.floor( distance / velocity *1000 ) -- in milliseconds

	return time
end



--====================================================================--
-- UFO class
--====================================================================--

local UFO = inheritsFrom( CoronaBase )
UFO.NAME = "Unidentified Flying Object"

--== Class constants

UFO.IMG_W = 110
UFO.IMG_H = 65

-- constants for speeds
UFO.FAST = 'fast_speed_key'
UFO.MEDIUM = 'medium_speed_key'
UFO.SLOW = 'slow_speed_key'

-- speeds, pixels per second
-- use constants for easier lookup
UFO.SPEEDS = {}
UFO.SPEEDS[UFO.FAST] = 350
UFO.SPEEDS[UFO.MEDIUM] = 150
UFO.SPEEDS[UFO.SLOW] = 50

-- images for each speed
UFO.COOL_IMG = "assets/ufo_cool.png"
UFO.WARM_IMG = "assets/ufo_warm.png"
UFO.HOT_IMG = "assets/ufo_hot.png"


--== Event Constants
UFO.EVENT = "ufo_event"
UFO.TOUCHED = "ufo_touched_event"




--== Start: Setup DMC Objects

-- initialize and list class properties
--
function UFO:_init( params )
	self:superCall( "_init", params )
	--==--

	--== Create Properties ==--

	self._transition = nil -- handle to a currently running transition


	--== Display Groups ==--

	--== Object References ==--

	self._ufo_bg = nil  -- background image, for taps
	self._ufo_views = {} -- dictionary of image, keyed on constants

end

function UFO:_undoInit()

	--== Object References ==--

	self._ufo_bg = nil
	self._ufo_views = nil

	--== Display Groups ==--

	--== Create Properties ==--

	self._transition = nil

	--==--
	self:superCall( "_undoInit" )
end


-- create view elements for UFO
--
function UFO:_createView()
	self:superCall( "_createView" )
	--==--

	local ufo_views = self._ufo_views -- make code easier to read
	local o


	--== Setup background

	o = display.newRect( 0, 0, UFO.IMG_W, UFO.IMG_H )
	o:setReferencePoint(display.CenterReferencePoint)
	o.x, o.y = 0, 0
	o.alpha = 0.05 -- just enough to allow a tap

	self:insert( o )
	self._ufo_bg = o


	--== Setup UFO Images

	-- setup cool
	o = display.newImageRect( UFO.COOL_IMG, UFO.IMG_W, UFO.IMG_H )
	o.isVisible = false

	self:insert( o )
	ufo_views[UFO.SLOW] = o

	-- setup warm
	o = display.newImageRect( UFO.WARM_IMG, UFO.IMG_W, UFO.IMG_H )
	o.isVisible = false

	self:insert( o )
	ufo_views[UFO.MEDIUM] = o

	-- setup hot
	o = display.newImageRect( UFO.HOT_IMG, UFO.IMG_W, UFO.IMG_H )
	o.isVisible = false

	self:insert( o )
	ufo_views[UFO.FAST] = o

end

-- remove all display elements during destruction
--
function UFO:_undoCreateView()

	local ufo_views = self._ufo_views -- make code easier to read
	local o

	--== Remove UFO Images

	o = ufo_views[UFO.SLOW]
	ufo_views[UFO.SLOW] = nil
	o:removeSelf()

	o = ufo_views[UFO.MEDIUM]
	ufo_views[UFO.MEDIUM] = nil
	o:removeSelf()

	o = ufo_views[UFO.FAST]
	ufo_views[UFO.FAST] = nil
	o:removeSelf()


	--== Remove Background

	o = self._ufo_bg 
	self._ufo_bg = nil
	o:removeSelf()


	--==--
	self:superCall( "_undoCreateView" )
end


-- do final setup after create
-- 
function UFO:_initComplete()
	self:superCall( "_initComplete" )
	--==--

	local o

	-- watch for touches on background
	o = self._ufo_bg
	o:addEventListener( "touch", self )

	-- show our "resting" image
	self._ufo_views[UFO.SLOW].isVisible = true

	-- randomly select a location on the display
	self:_setRandomLocation()

end

function UFO:_undoInitComplete()

	local o

	o = self._ufo_bg
	o:removeEventListener( "touch", self )

	self:_stopAnimation()


	--==--
	self:superCall( "_undoInitComplete" )
end



--== END: Setup DMC Objects





--== Public Methods



-- animate to new, random location
--
function UFO:move( speed )

	local coords, velocity, time

	coords = self:_getRandomLocation()
	velocity = UFO.SPEEDS[ speed ]
	time = calculateTime( self.x, self.y, coords.x, coords.y, velocity )

	self:_stopAnimation()
	self:_updateView( speed )
	self:_moveToLocation( coords.x, coords.y, time )
end




--== Private Methods



-- get random x,y coordinates
--
function UFO:_getRandomLocation()

	local W, H = display.viewableContentWidth, display.viewableContentHeight

	-- get number within our screen bounds
	local x = getRandomNumber( 0+UFO.IMG_W/2, W-UFO.IMG_W/2 )
	local y = getRandomNumber( 0+UFO.IMG_H/2, H-UFO.IMG_H/2 )

	return { x=x, y=y }
end


-- give ufo new coordinates, instantly
--
function UFO:_setRandomLocation()
	local coords = self:_getRandomLocation()	
	self.x, self.y = coords.x, coords.y
end


-- update the view of the ship depending on its linear velocity
--
function UFO:_updateView( speed )

	local views = self._ufo_views

	-- turn off all of our views
	views[UFO.SLOW].isVisible = false
	views[UFO.MEDIUM].isVisible = false
	views[UFO.FAST].isVisible = false

	-- then select the next view to show
	views[speed].isVisible = true

end



-- stop any current animation
--
function UFO:_stopAnimation()
	if self._transition ~= nil then
		transition.cancel( self._transition )
		self._transition = nil
	end
end

-- animate to new location
--
function UFO:_moveToLocation( x, y, time )

	local f 

	-- callback when animation completes
	f = function()
		self._transition = nil
		self:_updateView( UFO.SLOW )
	end

	-- start new animation
	self._transition = transition.to( self, { time=time, x=x, y=y, onComplete=f })

end




--== Event Handlers


-- handler for touch events
--
function UFO:touch( event )
	if event.phase == 'ended' then 
		self:_dispatchEvent( UFO.TOUCHED )
	end
	return true
end


-- event dispatch helper
--
function UFO:_dispatchEvent( e_type, data )

	-- setup custom event
	local e = {
		name = UFO.EVENT,
		type = e_type,
		target = self,
		data = data
	}

	self:dispatchEvent( e )
end



return UFO

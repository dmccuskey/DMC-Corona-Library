
--====================================================================--
-- Imports and Setup
--====================================================================--

-- import DMC Objects file
local Objects = require( "dmc_objects" )

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase

local Utils = require( "dmc_utils" )
local rand = math.random


-- setup the bounding area for the ships
local SPACE_BOUNDS = display.newRect( 0, 0, display.viewableContentWidth,
	display.viewableContentHeight )
SPACE_BOUNDS:setFillColor( 0, 0, 0, 0 )



--====================================================================--
-- UFO class
--====================================================================--

local UFO = inheritsFrom( CoronaBase )
UFO.NAME = "Unidentified Flying Object"


-- Class constants

UFO.COOL_IMG = "assets/ufo_cool.png"
UFO.WARM_IMG = "assets/ufo_warm.png"
UFO.HOT_IMG = "assets/ufo_hot.png"
UFO.IMG_W = 110
UFO.IMG_H = 65

UFO.TRANSITION_TIME = 1500
UFO.CHANGE_TIME = 4000


--==  Class constructor  ==--

function UFO:new()

	local o = self:_bless()
	o:_init()
	o:_createView()
	o:_initComplete()

	return o
end


--==  Methods  ==--


-- _init()
--
-- one of the base methods to override for dmc_objects
-- put on our object properties
--
function UFO:_init()

	-- be sure to call this first !
	self:superCall( "_init" )

	-- == Create Properties ==

	-- our velocity
	self.vx = 0
	self.vy = 0

	-- image views
	self._ufo_views = {}

	-- velocity change vars
	self.isChangingSpeed = false
	self.vxTarget = 0
	self.vyTarget = 0
	self.changeStart = 0
	self.transition = nil

end


-- _createView()
--
-- one of the base methods to override for dmc_objects
-- assemble the images for our object
--
function UFO:_createView()

	local ufo_views = self._ufo_views
	local img

	-- setup cool
	img = display.newImageRect( UFO.COOL_IMG, UFO.IMG_W, UFO.IMG_H )
	self:insert( img )
	ufo_views.cool = img
	img.isVisible = false

	-- setup warm
	img = display.newImageRect( UFO.WARM_IMG, UFO.IMG_W, UFO.IMG_H )
	self:insert( img )
	ufo_views.warm = img
	img.isVisible = false

	-- setup hot
	img = display.newImageRect( UFO.HOT_IMG, UFO.IMG_W, UFO.IMG_H )
	self:insert( img )
	ufo_views.hot = img
	img.isVisible = false

end


-- _initComplete()
-- any setup after object is done being created
--
function UFO:_initComplete()

	-- pick a direction/velocity for our UFO

	self:_changeCourse()


	-- start our actions/listeners

	timer.performWithDelay( UFO.CHANGE_TIME,
		Utils.createObjectCallback( self, self._changeCourse ), 0 )

	Runtime:addEventListener( "enterFrame", self )

end


-- _updateView()
--
-- update the view of the ship depending on its linear velocity
--
function UFO:_updateView( flipX, flipY )

	local currTime = system.getTimer()
	local timeDiff = currTime - self.changeStart
	if flipX or flipY then

		if flipX then self.vxTarget = -self.vxTarget end
		if flipY then self.vyTarget = -self.vyTarget end
		self:_createTransition()

	end

	-- calculate linear velocity - pythagorian theorem
	local v = math.sqrt( self.vx^2 + self.vy^2 )

	-- turn off all of our views
	self._ufo_views.cool.isVisible = false
	self._ufo_views.warm.isVisible = false
	self._ufo_views.hot.isVisible = false

	-- then select the next view to show
	if v < 6 then
		self._ufo_views.cool.isVisible = true
	elseif v < 10 then
		self._ufo_views.warm.isVisible = true
	else
		self._ufo_views.hot.isVisible = true
	end

end


-- _changeCourse()
--
-- randomize new direction - velocities for x and y
--
function UFO:_changeCourse( event )

	local r, xRand, yRand
	local nvx, nvy

	-- randomize velocity ranges
	r = rand( 0, 100 )
	if r < 50 then
		xRand = 5
	elseif r < 80 then
		xRand = 10
	else
		xRand = 15
	end
	r = rand( 0, 100 )
	if r < 50 then
		yRand = 0
	elseif r < 80 then
		yRand = 5
	else
		yRand = 10
	end

	-- randomize the velocities
	nvx = rand( -xRand, xRand ) + rand( -yRand, yRand )
	nvy = rand( -xRand, xRand ) + rand( -yRand, yRand )

	self.vxTarget = nvx
	self.vyTarget = nvy

	self.changeStart = system.getTimer()
	self:_createTransition()
	self:_updateView()

end

function UFO:_createTransition()

	if self.transition then transition.cancel( self.transition ) end

	self.isChangingSpeed = true
	local timeDiff = UFO.TRANSITION_TIME - ( system.getTimer() - self.changeStart  )
	self.transition = transition.to( self, { time=timeDiff,
		vx=self.vxTarget, vy=self.vyTarget,
		onComplete=Utils.createObjectCallback( self, self._speedChangeComplete ) } )

end


-- _speedChangeComplete()
--
-- done updating our speed, so turn off updates
--
function UFO:_speedChangeComplete( event )

	self.changeStart = 0
	self.isChangingSpeed = false
	if self.transition then transition.cancel( self.transition ) end
	self.transition = nil

end


-- enterFrame()
--
-- Corona Event Listener
-- put our UFO in motion
--
function UFO:enterFrame( event )

	local spaceBounds = SPACE_BOUNDS.contentBounds
	local xMin = spaceBounds.xMin
	local xMax = spaceBounds.xMax
	local yMin = spaceBounds.yMin
	local yMax = spaceBounds.yMax

	local bounds = self.contentBounds

	local dx = self.vx
	local dy = self.vy

	local flipX = false
	local flipY = false

	if ( bounds.xMax + dx ) > xMax then
		flipX = true
		dx = xMax - bounds.xMax
	elseif ( bounds.xMin + dx ) < xMin then
		flipX = true
		dx = xMin - bounds.xMin
	end

	if ( bounds.yMax + dy ) > yMax then
		flipY = true
		dy = yMax - bounds.yMax
	elseif ( bounds.yMin + dy ) < yMin then
		flipY = true
		dy = yMin - bounds.yMin
	end

	if ( flipX ) then
		self.vx = -self.vx
	end
	if ( flipY ) then
		self.vy = -self.vy
	end

	self:translate( dx, dy )

	if self.isChangingSpeed then
		self:_updateView( flipX, flipY )
	end

end




-- The Factory

local UFOFactory = {}

function UFOFactory.create()
	return UFO:new()
end


return UFOFactory


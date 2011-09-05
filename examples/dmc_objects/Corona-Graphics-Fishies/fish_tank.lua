

local Objects = require( "dmc_objects" )
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase


local FishTank = inheritsFrom( CoronaBase )
FishTank.NAME = "Fish Tank"

FishTank.REFLECT_X = true
-- Preload the sound file (theoretically, we should also dispose of it when we are completely done with it)
FishTank.SOUND = audio.loadSound( "assets/bubble_strong_wav.wav" )



--[[
-- don't actually need to have our constructor because
-- functionality comes from CoronaBase
-- it's just here for reference
--
function FishTank:new( options )

	local o = self:_bless()
	o:_init( options )
	o:_createView()
	o:_initComplete()

	return o
end
--]]



function FishTank:_init()

	self:superCall( "_init" )

	-- == Create Properties ==

	-- these will be the images
	self.backgroundPortrait = nil
	self.backgroundLandscape = nil

	-- current background image, selected via orientation handler
	self.background = nil

	self.currentOrientation = "portrait"
	self.container = nil
	self.theFish = {}

end


function FishTank:_createView()

	-- we didn't use the built-in display object, because
	-- that would have required us to change the names of the vars and we
	-- wanted to keep this as much like the original code as possible

	self.backgroundPortrait = display.newImage( "assets/aquariumbackgroundIPhone.jpg", 0, 0 )

	self.backgroundLandscape = display.newImage( "assets/aquariumbackgroundIPhoneLandscape.jpg", -80, 80 )
	self.backgroundLandscape.isVisible = false

	self.background = self.backgroundPortrait

	self.container = display.newRect( 0, 0, display.viewableContentWidth, display.viewableContentHeight )
	self.container:setFillColor( 0, 0, 0, 0)	-- make invisible

end


function FishTank:_initComplete()

	-- add some event listeners for those events we'd like to know about

	Runtime:addEventListener( "enterFrame", self )
	Runtime:addEventListener( "orientation", self )

end


function FishTank:addFish( fish )

	local halfW = display.viewableContentWidth / 2
	local halfH = display.viewableContentHeight / 2

	-- save the fish in our tank
	table.insert( self.theFish, fish )

	-- move to random position in a 200x200 region in the middle of the screen
	fish.x = halfW + math.random( -100, 100 )
	fish.y = halfH + math.random( -100, 100 )

end



function FishTank:enterFrame( event )

	local containerBounds = self.container.contentBounds
	local xMin = containerBounds.xMin
	local xMax = containerBounds.xMax
	local yMin = containerBounds.yMin
	local yMax = containerBounds.yMax

	local orientation = self.currentOrientation
	local isLandscape = "landscapeLeft" == orientation or "landscapeRight" == orientation

	local reflectX = nil ~= FishTank.REFLECT_X
	local reflectY = nil ~= FishTank.REFLECT_Y

	-- the fish groups are stored in integer arrays, so iterate through all the
	-- integer arrays
	for i,v in ipairs( self.theFish ) do
		local object = v  -- the display object to animate, e.g. the fish group
		local vx = object.vx
		local vy = object.vy

		if ( isLandscape ) then
			if ( "landscapeLeft" == orientation ) then
				local vxOld = vx
				vx = -vy
				vy = -vxOld
			elseif ( "landscapeRight" == orientation ) then
				local vxOld = vx
				vx = vy
				vy = vxOld
			end
		elseif ( "portraitUpsideDown" == orientation ) then
			vx = -vx
			vy = -vy
		end

		-- TODO: for now, time is measured in frames instead of seconds...
		local dx = vx
		local dy = vy

		local bounds = object.contentBounds

		local flipX = false
		local flipY = false

		if (bounds.xMax + dx) > xMax then
			flipX = true
			dx = xMax - bounds.xMax
		elseif (bounds.xMin + dx) < xMin then
			flipX = true
			dx = xMin - bounds.xMin
		end

		if (bounds.yMax + dy) > yMax then
			flipY = true
			dy = yMax - bounds.yMax
		elseif (bounds.yMin + dy) < yMin then
			flipY = true
			dy = yMin - bounds.yMin
		end

		if ( isLandscape ) then flipX,flipY = flipY,flipX end
		if ( flipX ) then
			object.vx = -object.vx
			if ( reflectX ) then object:scale( -1, 1 ) end
		end
		if ( flipY ) then
			object.vy = -object.vy
			if ( reflectY ) then object:scale( 1, -1 ) end
		end

		object:translate( dx, dy )

	end

end


-- Handle changes in orientation for the background images
function FishTank:orientation( event )

	-- TODO: This requires some setup, i.e. the landscape needs to be centered
	-- Need to add a centering operation.  For now, the position is hard coded
	self.currentOrientation = event.type
	local delta = event.delta
	if ( delta ~= 0 ) then
		local rotateParams = { rotation=-delta, time=500, delta=true }

		if ( delta == 90 or delta == -90 ) then
			local src = self.background

			-- toggle background to refer to correct dst
			self.background = ( self.backgroundLandscape == self.background and self.backgroundPortrait ) or self.backgroundLandscape
			self.background.rotation = src.rotation
			transition.dissolve( src, self.background )
			transition.to( src, rotateParams )
		else
			assert( 180 == delta or -180 == delta )
		end

		transition.to( self.background, rotateParams )

		audio.play( FishTank.SOUND )	-- play preloaded sound file
	end
end



return FishTank

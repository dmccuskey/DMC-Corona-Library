

--====================================================================--
-- Imports
--====================================================================--

local Objects = require( "dmc_objects" )
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase


--====================================================================--
-- Fish Object
--====================================================================--

local Fish = inheritsFrom( CoronaBase )
Fish.NAME = "A Fish"

Fish.file1 = "assets/fish.small.red.png"
Fish.file2 = "assets/fish.small.blue.png"


function Fish:new()

	local o = self:_bless()
	o:_init()
	o:_createView()

	return o
end



function Fish:_init()

	self:superCall( "_init" )

	-- == Create Properties ==

	-- assign each fish a random velocity
	self.vx = math.random( 1, 5 )
	self.vy = math.random( -2, 2 )


	-- add some event listeners for those events we'd like to know about

	self:addEventListener( "touch", self )
	Runtime:addEventListener( "orientation", self )

end


function Fish:_createView()

	local img

	-- fish original
	img = display.newImage( Fish.file1 )
	self:insert( img, true )

	-- fish different
	img = display.newImage( Fish.file2 )
	img.isVisible = false
	self:insert( img, true )

end



-- for some reason, scaling doesn't work around the proper reference point
-- need to figure out why
-- for now, just flip each image individually
--
-- it's a great name for a method - Fish Scale !
function Fish:scale( x, y )

	local d = self.display

	d[1]:scale( x, y )
	d[2]:scale( x, y )

end


function Fish:touch( event )

	local group = self.display

	if event.phase == "ended" then

		local topObject = group[1]

		if ( topObject.isVisible ) then
			local bottomObject = group[2]

			-- Dissolve to bottomObject (different color)
			transition.dissolve( topObject, bottomObject, 500 )

			-- Restore after some random delay
			transition.dissolve( bottomObject, topObject, 500, math.random( 3000, 10000 ) )
		end

		return true
	end

end

function Fish:orientation( event )

	if ( event.delta ~= 0 ) then

		local rotateParameters = { rotation = -event.delta, time=500, delta=true }

		Runtime:removeEventListener( "enterFrame", self )

		transition.to( self.display, rotateParameters )

		local function resume( event )
			Runtime:addEventListener( "enterFrame", self )
		end

		timer.performWithDelay( 500, resume )
	end

end



--====================================================================--
-- Fish Store Factory
--====================================================================--

local FishStore = {}

FishStore.buyFish = function()
	return Fish:new()
end

return FishStore



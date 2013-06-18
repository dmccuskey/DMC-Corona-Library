print(" ------------------------------------------------ ")

--====================================================================--
-- Imports
--====================================================================--

local CrateFactory = require("crates")

local physics = require("physics")
physics.start()


--====================================================================--
-- Setup, Constants
--====================================================================--

local seed = os.time();
math.randomseed( seed )

if system.getInfo("environment") ~= 'simulator' then
	display.setStatusBar( display.HiddenStatusBar )
end


--====================================================================--
-- Main
--====================================================================--

-- ==========================
-- set background image

local bkg = display.newImage( "assets/bkg_cor.png" )


-- ==========================
-- setup Grass

-- grass for physics
local grass = display.newImage("assets/grass.png")
grass.x = 160; grass.y = 430
physics.addBody( grass, "static", { friction=0.5, bounce=0.3 } )


-- setup decorative Grass  ( non-physical decorative overlay )
local grass2 = display.newImage("assets/grass2.png")
grass2.x = 160; grass2.y = 440



-- ==========================
-- add our crates to the display

function addCrate()

	local crate = CrateFactory.create()

	crate.x = 60 + math.random( 160 )
	crate.y = -100

	physics.addBody( crate.display, crate:getPhysicsProps() )

end

local dropCrates = timer.performWithDelay( 500, addCrate, 100 )
print(" ------------------------------------------------ ")

--====================================================================--
-- Imports
--====================================================================--

local FishStore = require( "fish_store" )
local FishTank = require( "fish_tank" )


--====================================================================--
-- Setup, Constants
--====================================================================--

local seed = os.time();
math.randomseed( seed )

if system.getInfo("environment") ~= 'simulator' then
	display.setStatusBar( display.HiddenStatusBar )
end

-- how many fish in the tank

local numFish = 10


--====================================================================--
-- Main
--====================================================================--

-- create our brand new fish tank

local myFishTank = FishTank:new()


-- get some fish for it

for i=1, numFish do

	local fish = FishStore.buyFish()
	myFishTank:addFish( fish )

end

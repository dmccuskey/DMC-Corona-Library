print(" ------------------------------------------------ ")

local seed = os.time();
math.randomseed( seed )


display.setStatusBar( display.HiddenStatusBar )


-- do our imports

local FishStore = require( "fish_store" )
local FishTank = require( "fish_tank" )


-- how many fish in the tank

local numFish = 10


-- create our brand new fish tank

local myFishTank = FishTank:new()


-- get some fish for it

for i=1, numFish do

	local fish = FishStore.buyFish()
	myFishTank:addFish( fish )

end

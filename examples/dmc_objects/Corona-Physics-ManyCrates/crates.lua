
-- =====================================================
-- Imports
-- =====================================================

local Objects = require( "dmc_objects" )
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase



-- =====================================================
-- CRATE BASE CLASS
-- =====================================================


local CrateBase = inheritsFrom( CoronaBase )
CrateBase.IMAGE_SRC = nil


function CrateBase:new()

	local o = self:_bless()
	o:_init()
	o:_createView()

	return o
end


function CrateBase:_init()

	self:superCall( "_init" )

	-- == Create Properties ==

	self.density = nil
	self.friction = nil
	self.bounce = nil

end


function CrateBase:_createView()

	-- subclassing instantiates CrateBase, which has no image
	-- so test to make sure we have an image

	if self.IMAGE_SRC then

		-- since we only have a single image, let's replace the
		-- display group with the image object
		local d  = display.newImage( self.IMAGE_SRC );
		self:_setDisplay( d )
	end

end


function CrateBase:getPhysicsProps()

	return {
		density = self.density,
		friction = self.friction,
		bounce = self.bounce,
	}

end




-- =====================================================
-- LARGE CRATE CLASS
-- =====================================================

local LargeCrate = inheritsFrom( CrateBase )
LargeCrate.IMAGE_SRC = "assets/crateB.png"


function LargeCrate:_init()

	self:superCall( "_init" )

	-- == Create Properties ==

	self.density = 1.4
	self.friction = 0.3
	self.bounce = 0.3

end




-- =====================================================
-- MEDIUM CRATE CLASS
-- =====================================================

local MediumCrate = inheritsFrom( CrateBase )
MediumCrate.IMAGE_SRC = "assets/crate.png"


function MediumCrate:_init()

	self:superCall( "_init" )

	-- == Create Properties ==

	self.density = 0.9
	self.friction = 0.3
	self.bounce = 0.3

end




-- =====================================================
-- SMALL CRATE CLASS
-- =====================================================

local SmallCrate = inheritsFrom( CrateBase )
SmallCrate.IMAGE_SRC = "assets/crateC.png"


function SmallCrate:_init()

	self:superCall( "_init" )

	-- == Create Properties ==

	self.density = 0.3
	self.friction = 0.2
	self.bounce = 0.5

end




-- =====================================================
-- CRATE FACTORY
-- =====================================================


local function selectRandomCrate()
	local rand = math.random( 100 )

	local crateType = ""

	if rand < 60 then
		crateType = "medium"
	elseif rand < 80 then
		crateType = "large"
	else
		crateType = "small"
	end

	return crateType
end


local CrateFactory = {}

CrateFactory.create = function( crateType )

	local crateType = crateType or selectRandomCrate()
	local crate

	if crateType == "small" then
		crate = SmallCrate:new()

	elseif crateType == "medium" then
		crate = MediumCrate:new()

	elseif crateType == "large" then
		crate = LargeCrate:new()
	end

	return crate
end


return CrateFactory

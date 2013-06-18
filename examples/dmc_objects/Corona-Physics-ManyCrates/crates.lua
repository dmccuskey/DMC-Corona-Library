
-- =====================================================
-- Imports
-- =====================================================

local Objects = require( "dmc_objects" )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase


-- =====================================================
-- Crate Base Class
-- =====================================================

local CrateBase = inheritsFrom( CoronaBase )
CrateBase.IMAGE_SRC = nil


--== Start: Setup DMC Objects

-- do basic object init()
function CrateBase:_init()
	self:superCall( "_init" )
	--==--

	--== Create Properties ==--

	self.density = nil
	self.friction = nil
	self.bounce = nil

end
-- reverse init() setup
function CrateBase:_undoInit()
	self.density = nil
	self.friction = nil
	self.bounce = nil

	--==--
	self:superCall( "_undoInit" )
end

-- create basic object view
function CrateBase:_createView()
	self:superCall( "_createView" )
	--==--

	local o -- object tmp

	o  = display.newImage( self.IMAGE_SRC )
	--self:insert( o )
	--self:setReferencePoint(display.CenterReferencePoint)

	-- here we use our image for our view instead of default display group
	-- physics works better this way
	self:_setView( o )
end

--[[
if our setup was more complex than just Corona elements, 
we could specifically tear down the object's view here.
however, dmc_objects will automatically remove pure-Corona elements automatically
function Shape:_undoCreateView()
	--==--
	self:superCall( "_undoCreateView" )
end
--]]


--== END: Setup DMC Objects



--== Public Methods


function CrateBase:getPhysicsProps()

	return {
		density = self.density,
		friction = self.friction,
		bounce = self.bounce,
	}

end




--== Private Methods

-- none



-- =====================================================
-- LARGE CRATE CLASS
-- =====================================================

local LargeCrate = inheritsFrom( CrateBase )
LargeCrate.IMAGE_SRC = "assets/crateB.png"


function LargeCrate:_init()
	self:superCall( "_init" )
	--==--

	--== Create Properties ==--

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
	--==--

	--== Create Properties ==--

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
	--==--

	--== Create Properties ==--

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


--====================================================================--
-- Imports and Setup
--====================================================================--

-- import DMC Objects file
local Objects = require( "dmc_objects" )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase



--====================================================================--
-- Level One class
--====================================================================--

local One = inheritsFrom( CoronaBase )
One.NAME = "Level One"


--== Start: Setup DMC Objects


function One:_init( params )
	print( "One:_init" )
	self:superCall( "_init", params )
	--==--

	self._number = 0

end
function One:_undoInit()
	print( "One:_undoInit" )

	--==--
	self:superCall( "_undoInit" )
end


function One:_createView()
	print( "One:_createView" )
	self:superCall( "_createView" )
	--==--

	self._number = self._number + 1
end
function One:_undoCreateView()
	print( "One:_undoCreateView" )

	--==--
	self:superCall( "_undoCreateView" )
end

function One:_initComplete()
	print( "One:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	print( 'final ', self._number )

end
function One:_undoInitComplete()
	print( "One:_undoInitComplete" )

	--==--
	self:superCall( "_undoInitComplete" )
end



--== END: Setup DMC Objects




--====================================================================--
-- Level Two class
--====================================================================--

local Two = inheritsFrom( One )
Two.NAME = "Level Two"

function Two:_createView()
	print( "Two:_createView" )
	self:superCall( "_createView" )
	--==--

end

--====================================================================--
-- Level Three class
--====================================================================--

local Three = inheritsFrom( Two )
Three.NAME = "Level Three"

function Three:_init( params )
	print( "Three:_init" )
	self:superCall( "_init", params )
	--==--

	self._number = 2

end


--====================================================================--
-- Level Four class
--====================================================================--

local Four = inheritsFrom( Three )
Four.NAME = "Level Four"






--====================================================================--
-- Test Factory
--====================================================================--


-- Support Items


-- The Factory

local ClassFactory = {}

function ClassFactory.create( class, options )
	print( '-------------- ClassFactory.create', class )
	local o

	if ( class == "one" ) then
		o = One:new( options )

	elseif ( class == "two" ) then
		o = Two:new( options )

	elseif ( class == "three" ) then
		o = Three:new( options )

	elseif ( class == "four" ) then
		o = Four:new( options )

	else
		print ("Class Factory, unknown class!! " .. tostring( class ) )
	end

	return o
end


return ClassFactory


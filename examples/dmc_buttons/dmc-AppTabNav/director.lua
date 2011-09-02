module(..., package.seeall)

--====================================================================--
-- DIRECTOR CLASS
--====================================================================--

--[[

 - Version: 1.3
 - Made by Ricardo Rauber Pereira @ 2010
 - Blog: http://rauberlabs.blogspot.com/
 - Mail: ricardorauber@gmail.com

******************
 - INFORMATION
******************

  - This class is free to use, feel free to change but please send new versions
	or new features like new effects to me and help us to make it better!
  - Please take a look on the template.lua file and don't forget to always
	insert your display objects into the localGroup.
  - If you like Director Class, please help us donating at my blog so I could
	keep doing it for free. http://rauberlabs.blogspot.com/

******************
 - HISTORY
******************

 - 06-OCT-2010 - Ricardo Rauber - Created;
 - 07-OCT-2010 - Ricardo Rauber - Functions loadScene and fxEnded were
								  taken off from the changeScene function;
								  Added function cleanGroups for best
								  memory clean up;
								  Added directorView and effectView groups
								  for better and easier control;
								  Please see INFORMATION to know how to use it;
 - 14-NOV-2010 - Ricardo Rauber - Bux fixes and new getScene function to get
								  the name of the active scene (lua file);
 - 14-FEB-2011 - Ricardo Rauber - General Bug Fixes;
 - 26-APR-2011 - Ricardo Rauber - cleanGroups() changed; Added Pop Up;
 - 21-JUN-2011 - Ricardo Rauber - Added error control; cleanGroups() removed;
								  Added touch protection; loadScene() changed;
								  Effects improved; Send Parameters; Bug fixes;

 --]]

print("-----------------------------------------------")

--====================================================================--
-- CONTENT INFO
--====================================================================--

local _W = display.contentWidth
local _H = display.contentHeight

--====================================================================--
-- DISPLAY GROUPS
--====================================================================--

directorView = display.newGroup()
--
local currView       = display.newGroup()
local nextView       = display.newGroup()
local protectionView = display.newGroup()
local popupView      = display.newGroup()
local effectView     = display.newGroup()
--
local initViews = function ()
	directorView:insert( currView )
	directorView:insert( nextView )
	directorView:insert( protectionView )
	directorView:insert( popupView )
	directorView:insert( effectView )
end

--====================================================================--
-- VARIABLES
--====================================================================--

local currScreen, nextScreen, popupScreen
local currScene, nextScene, popupScene = "main", "main", "main"
local newScene
local fxTime = 200
local safeDelay = 50
local isChangingScene = false
local popUpOnClose
--
currView.x = 0
currView.y = 0
nextView.x = _W
nextView.y = 0
popupView.x = 0
popupView.y = 0

--====================================================================--
-- GET COLOR
--====================================================================--

local getColor = function ( strValue1, strValue2, strValue3 )
	
	------------------
	-- Variables
	------------------
	
	local r, g, b
	
	------------------
	-- Test Parameters
	------------------
	
	if type(strValue1) == "nil" then
		strValue1 = "black"
	end
	
	------------------
	-- Find Color
	------------------
	
	if string.lower( tostring( strValue1 ) ) == "red" then
		r=255
		g=0
		b=0
	elseif string.lower( tostring( strValue1 ) ) == "green" then
		r=0
		g=255
		b=0
	elseif string.lower( tostring( strValue1 ) ) == "blue" then
		r=0
		g=0
		b=255
	elseif string.lower( tostring( strValue1 ) ) == "yellow" then
		r=255
		g=255
		b=0
	elseif string.lower( tostring( strValue1 ) ) == "pink" then
		r=255
		g=0
		b=255
	elseif string.lower( tostring( strValue1 ) ) == "white" then
		r=255
		g=255
		b=255
	elseif type ( strValue1 ) == "number"
	   and type ( strValue2 ) == "number"
	   and type ( strValue3 ) == "number" then
		r=strValue1
		g=strValue2
		b=strValue3
	else
		r=0
		g=0
		b=0
	end
	
	------------------
	-- Return
	------------------
	
	return r, g, b
	
end

--====================================================================--
-- SHOW ERRORS
--====================================================================--

local showError = function ( errorMessage )
	local str = "Director ERROR: " .. tostring( errorMessage )
	local function onComplete ( event )
		print ()
		print ( "-----------------------" )
		print ( str )
		print ( "-----------------------" )
		error ()
	end
	local alert = native.showAlert( "Director Class - ERROR", str, { "OK" }, onComplete )
end

--====================================================================--
-- GARBAGE COLLECTOR
--====================================================================--

local garbageCollect = function ( event )
	collectgarbage( "collect" )
end

--====================================================================--
-- IS DISPLAY OBJECT ?
--====================================================================--

local coronaMetaTable = getmetatable( display.getCurrentStage() )
--
local isDisplayObject = function ( aDisplayObject )
	return ( type( aDisplayObject ) == "table" and getmetatable( aDisplayObject ) == coronaMetaTable )
end

--====================================================================--
-- PROTECTION
--====================================================================--

------------------
-- Rectangle
------------------

local protection = display.newRect( -_W, -_H, _W * 3, _H * 3 )
protection:setFillColor( 255, 255, 255 )
protection.alpha = 0.01
protection.isVisible = false
protectionView:insert( protection )

------------------
-- Listener
------------------

local fncProtection = function ( event )
	return true
end
protection:addEventListener( "touch", fncProtection )

--====================================================================--
-- CHANGE CONTROLS
--====================================================================--

------------------
-- Effects Time
------------------

function director:changeFxTime ( newFxTime )
	if type( newFxTime ) == "number" then
		fxTime = newFxTime
	end
end

------------------
-- Safe Delay
------------------

function director:changeSafeDelay ( newSafeDelay )
	if type( newSafeDelay ) == "number" then
		safeDelay = newSafeDelay
	end
end

--====================================================================--
-- GET SCENES
--====================================================================--

------------------
-- Current
------------------

function director:getCurrScene ()
	return currScene
end

------------------
-- Next
------------------

function director:getNextScene ()
	return nextScene
end

--====================================================================--
-- UNLOAD SCENE
--====================================================================--

local unloadScene = function ( moduleName )
	if moduleName ~= "main" and type( package.loaded[moduleName] ) == "table" then
		package.loaded[moduleName] = nil
		local function garbage ( event )
			garbageCollect()
		end
		timer.performWithDelay( fxTime, garbage )
	end
end

--====================================================================--
-- LOAD SCENE
--====================================================================--
	
local loadScene = function ( moduleName, target, params )
	
	------------------
	-- Test parameters
	------------------
	
	if type( moduleName ) ~= "string" then
		showError ( "Module name must be a string. moduleName = " .. tostring( moduleName ) )
		return false
	end
	
	------------------
	-- Load Module
	------------------
	
	if not package.loaded[moduleName] then
		if not pcall ( require, moduleName ) then
			showError ( "Failed to load module '" .. moduleName .. "' - Please check if the file exists and it is correct." )
			return false
		end
	end
	
	------------------
	-- Serach new() Function
	------------------
	
	if not package.loaded[moduleName].new then
		showError ( "Module '" .. tostring( moduleName ) .. "' must have a new() function." )
		return false
	end
	--
	local functionName = package.loaded[moduleName].new
	
	------------------
	-- Variables
	------------------
	
	local handler
	
	------------------
	-- Load choosed scene
	------------------
	
	-- Curr
	if string.lower( target ) == "curr" then
		--
		currView:removeSelf()
		currView = display.newGroup()
		initViews()
		--
		if currScene ~= nextScene then
			unloadScene( moduleName )
		end
		--
		handler, currScreen = pcall( functionName, params )
		--
		if not handler then
			showError ( "Failed to execute " .. tostring( functionName ) .. "( params ) function on '" .. tostring( moduleName ) .. "'." )
			return false
		end
		--
		if not isDisplayObject( currScreen ) then
			showError ( "Module " .. moduleName .. " must return a display.newGroup()." )
			return false
		end
		--
		currView:insert(currScreen)
		currScene = moduleName
	
	-- Next
	else
		--
		nextView:removeSelf()
		nextView = display.newGroup()
		initViews()
		--
		if currScene ~= nextScene then
	 		unloadScene( moduleName )
	 	end
		--
		handler, nextScreen = pcall( functionName, params )
		--
		if not handler then
			showError ( "Failed to execute " .. tostring( functionName ) .. "( params ) function on '" .. tostring( moduleName ) .. "'." )
			return false
		end
		--
		if not isDisplayObject( nextScreen ) then
			showError ( "Module " .. moduleName .. " must return a display.newGroup()." )
			return false
		end
		--
		nextView:insert( nextScreen )
		nextScene = moduleName
		
	end
	
	------------------
	-- Return
	------------------
	
	return true
	
end

------------------
-- Load curr screen
------------------

local function loadCurrScene ( moduleName, params )
	loadScene ( moduleName, "curr", params )
end

------------------
-- Load next screen
------------------

local function loadNextScene ( moduleName, params )
	loadScene ( moduleName, "next", params )
end

--====================================================================--
-- EFFECT ENDED
--====================================================================--

local fxEnded = function ( event )
	
	------------------
	-- Reset current view
	------------------
	
	currView.x = 0
	currView.y = 0
	currView.xScale = 1
	currView.yScale = 1
	
	------------------
	-- Clean current scene
	------------------
	
	currView:removeSelf()
	currView = display.newGroup()
	initViews()
	
	------------------
	-- Unload scene
	------------------
	
	if currScene ~= nextScene then
		unloadScene( currScene )
	end
	
	------------------
	-- Next -> Current
	------------------
	
	currScreen = nextScreen
	currScene = newScene
	currView:insert( currScreen )
	
	------------------
	-- Reset next view
	------------------
	
	nextView.x = _W
	nextView.y = 0
	nextView.xScale = 1
	nextView.yScale = 1
	
	------------------
	-- Finish
	------------------
	
	isChangingScene = false
	protection.isVisible = false
	
	------------------
	-- Return
	------------------
	
	return true
	
end

--====================================================================--
-- CHANGE SCENE
--====================================================================--
	
function director:changeScene(params,
							  nextLoadScene,
							  effect,
							  arg1,
							  arg2,
							  arg3)
	
	------------------
	-- If is changing scene, return without do anything
	------------------
	
	if isChangingScene then
		return true
	else
		isChangingScene = true
	end
	
	------------------
	-- Test parameters
	------------------
	
	if type( params ) ~= "table" then
		arg3 = arg2
		arg2 = arg1
		arg1 = effect
		effect = nextLoadScene
		nextLoadScene = params
		params = nil
	end
	--
	if type( nextLoadScene ) ~= "string" then
		showError ( "The scene name must be a string. scene = " .. tostring( nextLoadScene ) )
		return false
	end
	
	------------------
	-- If is popup, don't change
	------------------
	
	if popupScene ~= "main" then
		return true
	end
	
	------------------
	-- Protection
	------------------
	
	protection.isVisible = true
	
	------------------
	-- Variables
	------------------
	
	newScene = nextLoadScene
	local showFx
	
	------------------
	-- Load Scene
	------------------
	
	loadNextScene ( newScene, params )
	
	------------------
	-- EFFECT: Move From Right
	------------------
	
	if effect == "moveFromRight" then
		
		nextView.x = _W
		nextView.y = 0
		--
		showFx = transition.to ( nextView, { x=0, time=fxTime } )
		showFx = transition.to ( currView, { x=-_W, time=fxTime, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Over From Right
	------------------
	
	elseif effect == "overFromRight" then
		
		nextView.x = _W
		nextView.y = 0
		--
		showFx = transition.to ( nextView, { x=0, time=fxTime, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Move From Left
	------------------
	
	elseif effect == "moveFromLeft" then
		
		nextView.x = -_W
		nextView.y = 0
		--
		showFx = transition.to ( nextView, { x=0, time=fxTime } )
		showFx = transition.to ( currView, { x=_W, time=fxTime, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Over From Left
	------------------
	
	elseif effect == "overFromLeft" then
		
		nextView.x = -_W
		nextView.y = 0
		--
		showFx = transition.to ( nextView, { x=0, time=fxTime, onComplete=fxEnded } )
		
	------------------
	-- EFFECT: Move From Top
	------------------
	
	elseif effect == "moveFromTop" then
		
		nextView.x = 0
		nextView.y = -_H
		--
		showFx = transition.to ( nextView, { y=0, time=fxTime } )
		showFx = transition.to ( currView, { y=_H, time=fxTime, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Over From Top
	------------------
	
	elseif effect == "overFromTop" then
		
		nextView.x = 0
		nextView.y = -_H
		--
		showFx = transition.to ( nextView, { y=0, time=fxTime, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Move From Bottom
	------------------
	
	elseif effect == "moveFromBottom" then
		
		nextView.x = 0
		nextView.y = _H
		--
		showFx = transition.to ( nextView, { y=0, time=fxTime } )
		showFx = transition.to ( currView, { y=-_H, time=fxTime, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Over From Bottom
	------------------
	
	elseif effect == "overFromBottom" then
		
		nextView.x = 0
		nextView.y = _H
		--
		showFx = transition.to ( nextView, { y=0, time=fxTime, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Crossfade
	------------------
	
	elseif effect == "crossfade" then
		
		nextView.x = _W
		nextView.y = 0
		--
		nextView.alpha = 0
		nextView.x = 0
		--
		showFx = transition.to ( nextView, { alpha=1, time=fxTime*2, onComplete=fxEnded } )
	
	------------------
	-- EFFECT: Fade
	------------------
	-- ARG1 = color [string]
	------------------
	-- ARG1 = red   [number]
	-- ARG2 = green [number]
	-- ARG3 = blue  [number]
	------------------
	
	elseif effect == "fade" then
		
		nextView.x = _W
		nextView.y = 0
		--
		local fade = display.newRect( -_W, -_H, _W * 3, _H * 3 )
		fade.alpha = 0
		fade:setFillColor( getColor ( arg1, arg2, arg3 ) )
		effectView:insert( fade )
		--
		local function returnFade ( event )
			nextView.x = 0
			--
			local function removeFade ( event )
				fade:removeSelf()
				fxEnded()
			end
			--
			showFx = transition.to ( fade, { alpha=0, time=fxTime, onComplete=removeFade } )
		end
		--
		showFx = transition.to ( fade, { alpha=1.0, time=fxTime, onComplete=returnFade } )
	
	------------------
	-- EFFECT: Flip
	------------------
	
	elseif effect == "flip" then
		
		nextView.xScale=0.001
		nextView.x=_W/2
		--
		local phase1, phase2
		--
		showFx = transition.to ( currView, { xScale=0.001, time=fxTime } )
		showFx = transition.to ( currView, { x=_W/2, time=fxTime } )
		--
		phase1 = function ( e )
			showFx = transition.to ( nextView, { xScale=0.001, x=_W/2, time=fxTime, onComplete=phase2 } )
		end
		--
		phase2 = function ( e )
			showFx = transition.to ( nextView, { xScale=1, x=0, time=fxTime, onComplete=fxEnded } )
		end
		--
		showFx = transition.to ( nextView, { time=0, onComplete=phase1 } )
	
	------------------
	-- EFFECT: Down Flip
	------------------
	
	elseif effect == "downFlip" then
		
		nextView.x = _W / 2
		nextView.y = _H * 0.15
		nextView.xScale = 0.001
		nextView.yScale = 0.7
		--
		local phase1, phase2, phase3, phase4
		--
		phase1 = function ( e )
			showFx = transition.to ( currView, { xScale=0.7, yScale=0.7, x=_W*0.15, y=_H*0.15, time=fxTime, onComplete=phase2 } )
		end
		--
		phase2 = function ( e )
			showFx = transition.to ( currView, { xScale=0.001, x=_W/2, time=fxTime, onComplete=phase3 } )
		end
		--
		phase3 = function ( e )
			showFx = transition.to ( nextView, { x=_W*0.15, xScale=0.7, time=fxTime, onComplete=phase4 } )
		end
		--
		phase4 = function ( e )
			showFx = transition.to ( nextView, { xScale=1, yScale=1, x=0, y=0, time=fxTime, onComplete=fxEnded } )
		end
		--
		showFx = transition.to ( currView, { time=0, onComplete=phase1 } )
	
	------------------
	-- EFFECT: None
	------------------
	
	else
		timer.performWithDelay( safeDelay, fxEnded )
	end
	
	------------------
	-- Return
	------------------
	
	return true
	
end

--====================================================================--
-- OPEN POPUP
--====================================================================--

function director:openPopUp ( params, newPopUpScene, onClose )
	
	------------------
	-- Test parameters
	------------------
	
	if type( params ) ~= "table" then
		onClose = newPopUpScene
		newPopUpScene = params
		params = nil
	end
	--
	if type( newPopUpScene ) ~= "string" then
		showError ( "Module name must be a string. moduleName = " .. tostring( newPopUpScene ) )
		return false
	end
	--
	if type( onClose ) == "function" then
		popUpOnClose = onClose
	end
	
	------------------
	-- Test scene name
	------------------
	
	if newPopUpScene == currScene
	or newPopUpScene == nextScene
	or newPopUpScene == "main"
	then
		return
	end
	
	------------------
	-- If is inside a popup, don't load
	------------------
	
	if popupScene ~= "main" then
		showError ( "Could not load a popup inside a popup." )
		return false
	end
	
	------------------
	-- Prepare scene
	------------------
	
	popupView:removeSelf()
	popupView = display.newGroup()
	initViews()
	--
	unloadScene( newPopUpScene )
	
	------------------
	-- Load scene
	------------------
	
	if not pcall ( require, newPopUpScene ) then
		showError ( "Failed to load module '" .. newPopUpScene .. "' - Please check if the file exists and it is correct." )
		return false
	end
	
	------------------
	-- Serach for new() function
	------------------
	
	if not package.loaded[newPopUpScene].new then
		showError ( "Module '" .. tostring( newPopUpScene ) .. "' must have a new() function." )
		return false
	end
	
	------------------
	-- Execute new() function
	------------------
	
	local functionName = package.loaded[newPopUpScene].new
	local handler
	--
	handler, popupScreen = pcall( functionName, params )
	--
	if not handler then
		showError ( "Failed to execute " .. tostring( functionName ) .. "( params ) function on '" .. tostring( moduleName ) .. "'." )
		return false
	end
	
	------------------
	-- Test if a group was returned
	------------------
	
	if not isDisplayObject( currScreen ) then
		showError ( "Module " .. moduleName .. " must return a display.newGroup()." )
		return false
	end
	--
	popupView:insert( popupScreen )
	popupScene = newPopUpScene
	
	------------------
	-- Protection
	------------------
	
	protection.isVisible = true
	
	------------------
	-- Return
	------------------
	
	return true
	
end

--====================================================================--
-- CLOSE POPUP
--====================================================================--

function director:closePopUp ()
	
	------------------
	-- If no popup is loaded, don't do anything
	------------------
	
	if popupScene == "main" then
		return true
	end
	
	------------------
	-- Unload scene
	------------------
	
	popupView:removeSelf()
	popupView = display.newGroup()
	initViews()
	--
	unloadScene( popupScene )
	--
	popupScene = "main"
	
	------------------
	-- Protection
	------------------
	
	protection.isVisible = false
	
	------------------
	-- Call function
	------------------
	
	if type( popUpOnClose ) == "function" then
		popUpOnClose()
	end
	
	------------------
	-- Return
	------------------
	
	return true
	
end
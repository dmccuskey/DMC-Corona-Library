--====================================================================--
-- App Tab Nav
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--


--====================================================================--
-- Imports
--====================================================================--

local director = require( "director" )

local ButtonFactory = require( "dmc_buttons" )
local RadioGroup = ButtonFactory.RadioGroup



--====================================================================--
-- Setup, Constants
--====================================================================--

display.setStatusBar( display.HiddenStatusBar )

local pageGroup = display.newGroup()
local mainGroup = display.newGroup()
local navDisplayGroup = display.newGroup()

-- put in groups so that we can maintain display order with tab menu
pageGroup:insert( mainGroup )
pageGroup:insert( navDisplayGroup )



--====================================================================--
-- Create Tab Group
--====================================================================--


	-----------------
	-- button group handler
	-----------------


	function handleButtonGroupChange( event )

		local eText = "EVENT: '" .. event.name .. "' button '" .. event.label .. "' to '" .. event.state .. "'"
		print ( eText )
		local button_label = event.label

		if button_label == "favorites" then
			director:changeScene("screen-favorites")
		elseif button_label == "recents" then
			director:changeScene("screen-recents")
		elseif button_label == "contacts" then
			director:changeScene("screen-contacts")
		elseif button_label == "keypad" then
			director:changeScene("screen-keypad")
		elseif button_label == "voicemail" then
			director:changeScene("screen-voicemail")
		end


		--local txt = textBox.text
		--textBox.text = eText
		--media.playEventSound( snd_toggle_btn_id )
	end



local function tabMenuSetup()

	local y_base = 450
	local radio

	---------------------
	-- tab group black background
	local tab_background = display.newImageRect( "assets/btn_tab_bg.png", 320, 56 )
	tab_background:setReferencePoint( display.BottomLeftReferencePoint )
	tab_background.x = 0
	tab_background.y = 480

	navDisplayGroup:insert( tab_background )


	---------------------
	-- radio group
	local radioGroup = ButtonFactory.create( "radioGroup" )
	navDisplayGroup:insert( radioGroup.display )

	-- we only need to listen to the group
	radioGroup:addEventListener( "change", handleButtonGroupChange )


	---------------------
	-- button: favorites
	radio = ButtonFactory.create( "radio", {
		id="favorites",
		width=42, height=49,
		activeSrc="assets/btn_tab_favorites_on.png",
		inactiveSrc="assets/btn_tab_favorites_off.png",
	})
	radio.x = 32
	radio.y = y_base

	radioGroup:add( radio )


	---------------------
	-- button: recents
	radio = ButtonFactory.create( "radio", {
		id="recents",
		width=38, height=46,
		activeSrc="assets/btn_tab_recents_on.png",
		inactiveSrc="assets/btn_tab_recents_off.png",
	})
	radio.x = 96
	radio.y = y_base

	radioGroup:add( radio )


	---------------------
	-- button: contacts
	radio = ButtonFactory.create( "radio", {
		id="contacts",
		width=40, height=46,
		activeSrc="assets/btn_tab_contacts_on.png",
		inactiveSrc="assets/btn_tab_contacts_off.png",
	})
	radio.x = 160
	radio.y = y_base

	radioGroup:add( radio )


	---------------------
	-- button: keypad
	radio = ButtonFactory.create( "radio", {
		id="keypad",
		width=34, height=44,
		activeSrc="assets/btn_tab_keypad_on.png",
		inactiveSrc="assets/btn_tab_keypad_off.png",
	})
	radio.x = 224
	radio.y = y_base

	radioGroup:add( radio )


	---------------------
	-- button: voicemail
	radio = ButtonFactory.create( "radio", {
		id="voicemail",
		width=46, height=44,
		activeSrc="assets/btn_tab_voicemail_on.png",
		inactiveSrc="assets/btn_tab_voicemail_off.png",
	})
	radio.x = 288
	radio.y = y_base

	radioGroup:add( radio )

end



local main = function ()

	mainGroup:insert( director.directorView )

	director:changeScene("screen-favorites")

end


if ( true ) then

	tabMenuSetup()
	main()

else

	--test( "screen-favorites" )
	--test( "screen-recents" )
	--test( "screen-contacts" )
	--test( "screen-keypad" )
	--test( "screen-voicemail" )

end

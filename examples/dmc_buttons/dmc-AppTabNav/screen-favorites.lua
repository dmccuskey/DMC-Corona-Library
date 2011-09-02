module(..., package.seeall)

--====================================================================--
-- SCENE: Favorites
--====================================================================--


new = function ( params )

	local localGroup = display.newGroup()

	-- page background
	local background = display.newImageRect( "assets/bg_generic.png", 320, 480 )
	background:setReferencePoint( display.TopLeftReferencePoint )
	background.x, background.y = 0, 0

	localGroup:insert( background )

	-- page title
	local textObj = display.newText( "Favorites", 0,0, nil, 35 );
	textObj:setTextColor( 128, 64, 0 )
	textObj:setReferencePoint( display.CenterReferencePoint )
	textObj.x, textObj.y = 160, 35

	localGroup:insert( textObj )

	return localGroup
end

-- ldoc configuration file

title = "DMC Corona Library API"
project = "DMC Corona Lib"
description = [[
Collection of Lua modules for the Corona SDK.
]]

alias("p","param")
tparam_alias("object","object")

--== Input 

file = {
	'dmc_corona/dmc_gestures.lua',
	'dmc_corona/dmc_gestures/pan_gesture.lua',
	'dmc_corona/dmc_gestures/pinch_gesture.lua',
	'dmc_corona/dmc_gestures/tap_gesture.lua',
	'dmc_corona/dmc_touchmanager.lua'
}

--== Output 

style="!fixed"
dir = "docs/api" 
output = "index"
ext = "html"


--====================================================================--
-- Config.lua
--
-- references
-- http://developer.coronalabs.com/content/configuring-projects
-- http://www.coronalabs.com/blog/2012/12/04/the-ultimate-config-lua-file/
--====================================================================--


local ratio = display.pixelHeight / display.pixelWidth


if string.sub(system.getInfo("model"),1,2) == "iP" and display.pixelHeight > 960 then
	application =
	{
		content =
		{
			width = 320,
			height = 568,
			scale = "letterBox",
			imageSuffix =
			{
				["@2x"] = 1.5,
			},
			fps = 60
		},
		notification =
		{
			iphone = {
				types = {
					"badge", "sound", "alert"
				}
			},
			google =
		    {
		      projectNumber = "565910089041",
		    },
		},
		showRuntimeErrors = false
	}


elseif string.sub(system.getInfo("model"),1,2) == "iP" then
	application =
	{
		content =
		{
			width = 320,
			height = 480,
			scale = "letterBox",
			imageSuffix =
			{
				["@2x"] = 2,
			},
			fps = 30
		},
		notification =
		{
			iphone = {
				types = {
					"badge", "sound", "alert"
				}
			},
			google =
		    {
		      projectNumber = "565910089041",
		    },
		},
		showRuntimeErrors = false
	}


--== 16:9 = 1.7778
elseif ratio > 1.77 then
	application =
	{
		content =
		{
			width = 320,
			height = 570,
			scale = "letterBox",
			imageSuffix =
			{
				["@2x"] = 2,
				["@hd"] = 3.0, -- only for HD android
			},
			fps = 60
		},
		notification =
		{
			google =
		    {
		      projectNumber = "565910089041",
		    },
		},
		showRuntimeErrors = false
	}


else -- 480 x 800
	application =
	{
		content =
		{
			width = 320,
			height = 533,
			scale = "letterBox",
			imageSuffix =
			{
				["@2x"] = 2,
			},
			fps = 30
		},
		notification =
		{
			google =
		    {
		      projectNumber = "565910089041",
		    },
		},
		showRuntimeErrors = false
	}
end

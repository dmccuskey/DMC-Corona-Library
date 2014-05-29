--====================================================================--
-- Config.lua
--
-- references
-- http://developer.coronalabs.com/content/configuring-projects
-- http://www.coronalabs.com/blog/2012/12/04/the-ultimate-config-lua-file/
--====================================================================--


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



# DMC-Corona-Library

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "DMC-Corona-Library"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "DMC-Corona-Library",
	"module": {
		"dir": "dmc_corona",
		"files": [
		],
		"requires": [
			"DMC-Lua-Library",
			"dmc-autostore",
			"dmc-files",
			"dmc-kozy",
			"dmc-netstream",
			"dmc-objects",
			"dmc-sockets",
			"dmc-utils",
			"dmc-websockets",
			"dmc-wamp"
		]
	},
	"tests": {
		"dir": "spec",
		"files": [],
		"requires": []
	}
}

register( "DMC-Corona-Library", module_config )



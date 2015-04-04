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
			"dmc_autostore.lua",
			"dmc_bytearray.lua",
			"dmc_dragdrop.lua",
			"dmc_e4x.lua",
			"dmc_error.lua",
			"dmc_events_mix.lua",
			"dmc_files.lua",

			"dmc_gestures.lua",
			"dmc_gestures/core/gesture.lua",
			"dmc_gestures/core/continuous_gesture.lua",
			"dmc_gestures/gesture_constants.lua",
			"dmc_gestures/gesture_manager.lua",
			"dmc_gestures/longpress_gesture.lua",
			"dmc_gestures/pan_gesture.lua",
			"dmc_gestures/pinch_gesture.lua",
			"dmc_gestures/tap_gesture.lua",

			"dmc_kolor.lua",
			"dmc_kolor/named_colors_hdr.lua",
			"dmc_kolor/named_colors_hex.lua",
			"dmc_kolor/named_colors_rgb.lua",

			"dmc_kozy.lua",

			"dmc_megaphone.lua",
			"dmc_lifecycle_mix.lua",
			"dmc_navigator.lua",
			"dmc_netstream.lua",
			"dmc_objects.lua",
			"dmc_patch.lua",
			"dmc_promise.lua",
			"dmc_states_mix.lua",
			"dmc_sockets.lua",
			"dmc_sockets/async_tcp.lua",
			"dmc_sockets/ssl_params.lua",
			"dmc_sockets/tcp.lua",
			"dmc_touchmanager.lua",
			"dmc_utils.lua",

			"dmc_wamp.lua",
			"dmc_wamp/auth.lua",
			"dmc_wamp/exception.lua",
			"dmc_wamp/future_mix.lua",
			"dmc_wamp/message.lua",
			"dmc_wamp/protocol.lua",
			"dmc_wamp/role.lua",
			"dmc_wamp/serializer.lua",
			"dmc_wamp/types.lua",
			"dmc_wamp/utils.lua",

			"dmc_websockets.lua",
			"dmc_websockets/exception.lua",
			"dmc_websockets/frame.lua",
			"dmc_websockets/handshake.lua",
			"dmc_websockets/message.lua"
		],
		"requires": [
			"dmc-corona-boot",
			"DMC-Lua-Library",
			"dmc-autostore",
			"dmc-bytearray",
			"dmc-dragdrop",
			"dmc-e4x",
			"dmc-error",
			"dmc-events-mixin",
			"dmc-files",
			"dmc-gestures",
			"dmc-kolor",
			"dmc-kozy",
			"dmc-megaphone",
			"dmc-lifecycle-mixin",
			"dmc-navigator",
			"dmc-netstream",
			"dmc-objects",
			"dmc-patch",
			"dmc-promise",
			"dmc-sockets",
			"dmc-states-mixin",
			"dmc-touchmanager",
			"dmc-utils",
			"dmc-wamp",
			"dmc-websockets"
		]
	},
	"tests": {
		"dir": "spec",
		"files": [],
		"requires": []
	}
}

register( "DMC-Corona-Library", module_config )



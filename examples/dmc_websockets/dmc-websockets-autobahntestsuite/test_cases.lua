--[[
Test Case Array for Autobahn WebSocket Test Suite

Entry:
{
	index='1',
	id='1.1.1',
	desc="Send text message with payload 0"
}
Comment out a line to disable that test
--]]


local test_cases = {

	--== 1.1 Framing, Text Msgs

	--[[
	--]]
	{ index='1', id='1.1.1', desc="Send text message with payload 0." },
	{ index='2', id='1.1.2', desc="Send text message message with payload of length 125" },
	{ index='3', id='1.1.3', desc="Send text message message with payload of length 126" },
	{ index='4', id='1.1.4', desc="Send text message message with payload of length 127" },
	{ index='5', id='1.1.5', desc="Send text message message with payload of length 128" },
	{ index='6', id='1.1.6', desc="Send text message message with payload of length 65535" },
	{ index='7', id='1.1.7', desc="Send text message message with payload of length 65536" },
	{ index='8', id='1.1.8', desc="Send text message message with payload of length 65536. Sent out data in chops of 997 octets" },


	--== 1.2 Framing, Binary Msgs

	-- BINARY NOT YET SUPPORTED

	-- { index='9', id='1.2.1', desc="echo empty binary msg, clean close, normal code " },
	-- { index='10', id='1.2.2', desc="echo binary msg 125 bytes, clean close, normal code " },
	-- { index='11', id='1.2.3', desc="echo binary msg 126 bytes, clean close, normal code " },
	-- { index='12', id='1.2.4', desc="echo binary msg 127 bytes, clean close, normal code " },
	-- { index='13', id='1.2.5', desc="echo binary msg 128 bytes, clean close, normal code " },
	-- { index='14', id='1.2.6', desc="echo binary msg 65535 bytes, clean close, normal code " },
	-- { index='15', id='1.2.7', desc="echo binary msg 65536 bytes, clean close, normal code " },
	-- { index='16', id='1.2.8', desc="echo binary msg 65536 bytes chopped, clean close, normal code " },


	--== 2 Pings/Pongs

	--[[
	--]]
	{ index='17', id='2.1', desc="Send ping without payload" },
	{ index='18', id='2.2', desc="Send ping with small text payload" },
	{ index='19', id='2.3', desc="Send ping with small binary (non UTF-8) payload" },
	{ index='20', id='2.4', desc="Send ping with binary payload of 125 octets" },
	{ index='21', id='2.5', desc="Send ping with binary payload of 126 octets" },
	{ index='22', id='2.6', desc="Send ping with binary payload of 125 octets, send in octet-wise chops" },
	{ index='23', id='2.7', desc="Send unsolicited pong without payload. Verify nothing is received. Clean close with normal code" },
	{ index='24', id='2.8', desc="Send unsolicited pong with payload. Verify nothing is received. Clean close with normal code" },
	{ index='25', id='2.9', desc="Send unsolicited pong with payload. Send ping with payload. Verify pong for ping is received" },
	{ index='26', id='2.10', desc="Send 10 Pings with payload" },
	{ index='27', id='2.11', desc="Send 10 Pings with payload. Send out octets in octet-wise chops" },


	--== 3 Reserved Bits

	--[[
	--]]
	{ index='28', id='3.1', desc="Send small text message with RSV = 1 " },
	{ index='29', id='3.2', desc="Send small text message, then send again with RSV = 2, then send Ping " },
	{ index='30', id='3.3', desc="Send small text message, then send again with RSV = 3, then send Ping. Octets are sent in frame-wise chops. Octets are sent in octet-wise chops " },
	{ index='31', id='3.4', desc="Send small text message, then send again with RSV = 4, then send Ping. Octets are sent in octet-wise chops " },
	{ index='32', id='3.5', desc="Send small binary message with RSV = 5" },
	{ index='33', id='3.6', desc="Send Ping with RSV = 6 " },
	{ index='34', id='3.7', desc="Send Close with RSV = 7 " },


	--== 4.1 Opcodes, non-control

	--[[
	--]]
	{ index='35', id='4.1.1', desc="Send frame with reserved non-control Opcode = 3; error close, code 1002" },
	{ index='36', id='4.1.2', desc="Send frame with reserved non-control Opcode = 4 and non-empty payload; error close, code 1002" },
	{ index='37', id='4.1.3', desc="Send small text message, then send frame with reserved non-control Opcode = 5, then send Ping; echo then error close, code 1002" },
	{ index='38', id='4.1.4', desc="Send small text message, then send frame with reserved non-control Opcode = 6 and non-empty payload, then send Ping; echo then error close, code 1002" },
	{ index='39', id='4.1.5', desc="Send small text message, then send frame with reserved non-control Opcode = 7 and non-empty payload, then send Ping; echo then error close, code 1002" },


	--== 4.2 Opcodes, control

	--[[
	--]]
	{ index='40', id='4.2.1', desc="Send frame with reserved control Opcode = 11" },
	{ index='41', id='4.2.2', desc="Send frame with reserved control Opcode = 12 and non-empty payload" },
	{ index='42', id='4.2.3', desc="Send small text message, then send frame with reserved control Opcode = 13, then send Ping" },
	{ index='43', id='4.2.4', desc="Send small text message, then send frame with reserved control Opcode = 14 and non-empty payload, then send Ping" },
	{ index='44', id='4.2.5', desc="Send small text message, then send frame with reserved control Opcode = 15 and non-empty payload, then send Ping" },


	--== 5 Fragmentation

	--[[
	--]]
	{ index='45', id='5.1', desc="Send Ping fragmented into 2 fragments" },
	{ index='46', id='5.2', desc="Send Pong fragmented into 2 fragments" },
	{ index='47', id='5.3', desc="Send text Message fragmented into 2 fragments" },
	{ index='48', id='5.4', desc="Send text Message fragmented into 2 fragments, octets are sent in frame-wise chops" },
	{ index='49', id='5.5', desc="Send text Message fragmented into 2 fragments, octets are sent in octet-wise chops" },
	{ index='50', id='5.6', desc="Send text Message fragmented into 2 fragments, one ping with payload in-between" },
	{ index='51', id='5.7', desc="Send text Message fragmented into 2 fragments, one ping with payload in-between. Octets are sent in frame-wise chops" },
	{ index='52', id='5.8', desc="Send text Message fragmented into 2 fragments, one ping with payload in-between. Octets are sent in octet-wise chops" },
	{ index='53', id='5.9', desc="Send unfragmented Text Message after Continuation Frame with FIN = true, where there is nothing to continue, sent in one chop" },
	{ index='54', id='5.10', desc="Send unfragmented Text Message after Continuation Frame with FIN = true, where there is nothing to continue, sent in per-frame chops" },
	{ index='55', id='5.11', desc="Send unfragmented Text Message after Continuation Frame with FIN = true, where there is nothing to continue, sent in octet-wise chops" },
	{ index='56', id='5.12', desc="Send unfragmented Text Message after Continuation Frame with FIN = false, where there is nothing to continue, sent in one chop" },
	{ index='57', id='5.13', desc="Send unfragmented Text Message after Continuation Frame with FIN = false, where there is nothing to continue, sent in per-frame chops" },
	{ index='58', id='5.14', desc="Send unfragmented Text Message after Continuation Frame with FIN = false, where there is nothing to continue, sent in octet-wise chops" },
	{ index='59', id='5.15', desc="Send text Message fragmented into 2 fragments, then Continuation Frame with FIN = false where there is nothing to continue, then unfragmented Text Message, all sent in one chop" },
	{ index='60', id='5.16', desc="Repeated 2x: Continuation Frame with FIN = false (where there is nothing to continue), then text Message fragmented into 2 fragments" },
	{ index='61', id='5.17', desc="Repeated 2x: Continuation Frame with FIN = true (where there is nothing to continue), then text Message fragmented into 2 fragments" },
	{ index='62', id='5.18', desc="Send text Message fragmented into 2 fragments, with both frame opcodes set to text, sent in one chop." },
	{ index='63', id='5.19', desc="A fragmented text message is sent in multiple frames. After sending the first 2 frames of the text message, a Ping is sent. Then we wait 1s, then we send 2 more text fragments, another Ping and then the final text fragment. Everything is legal." },
	{ index='64', id='5.20', desc="Same as Case 5.19, but send all frames with SYNC = True. Note, this does not change the octets sent in any way, only how the stream is chopped up on the wire" },


	--== 6.1 UTF8 Handling, Valid UTF-8 with zero payload fragments

	--[[
	{ index='65', id='6.1.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='66', id='6.1.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='67', id='6.1.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	--]]

	--== 6.2 UTF8 Handling, Valid UTF-8 with zero payload fragments

	--[[
	{ index='68', id='6.2.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='69', id='6.2.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='70', id='6.2.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='71', id='6.2.4', desc="send ping fragmented into two fragments; error close, code 1002" },
	--]]

	--== 6.3 UTF8 Handling, Valid UTF-8 with zero payload fragments

	-- { index='72', id='6.3.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='73', id='6.3.2', desc="send ping fragmented into two fragments; error close, code 1002" },

	--== 6.4 UTF8 Handling, Valid UTF-8 with zero payload fragments

	-- { index='74', id='6.4.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='75', id='6.4.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='76', id='6.4.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='77', id='6.4.4', desc="send ping fragmented into two fragments; error close, code 1002" },

	--== 6.5 UTF8 Handling, Valid UTF-8 with zero payload fragments

	--[[
	{ index='78', id='6.5.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='79', id='6.5.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='80', id='6.5.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='81', id='6.5.4', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='82', id='6.5.5', desc="send ping fragmented into two fragments; error close, code 1002" },
	--]]

	--== 6.6 UTF8 Handling, Valid UTF-8 with zero payload fragments

	-- { index='83', id='6.6.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='84', id='6.6.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='85', id='6.6.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='86', id='6.6.4', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='87', id='6.6.5', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='88', id='6.6.6', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='89', id='6.6.7', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='90', id='6.6.8', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='91', id='6.6.9', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='92', id='6.6.10', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='93', id='6.6.11', desc="send ping fragmented into two fragments; error close, code 1002" },
	--[[--]]

	--== 6.7 UTF8 Handling, Valid UTF-8 with zero payload fragments

	--[[
	{ index='94', id='6.7.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='95', id='6.7.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='96', id='6.7.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='97', id='6.7.4', desc="send ping fragmented into two fragments; error close, code 1002" },
	--]]

	--== 6.8 UTF8 Handling, Valid UTF-8 with zero payload fragments

	-- { index='98', id='6.8.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='99', id='6.8.2', desc="send ping fragmented into two fragments; error close, code 1002" },

	--== 6.9 UTF8 Handling, Valid UTF-8 with zero payload fragments

	--[[
	{ index='100', id='6.9.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='101', id='6.9.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='102', id='6.9.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='103', id='6.9.4', desc="send ping fragmented into two fragments; error close, code 1002" },
	--]]

	--== 6.10 UTF8 Handling, Valid UTF-8 with zero payload fragments

	-- { index='104', id='6.10.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='105', id='6.10.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	-- { index='106', id='6.10.3', desc="send ping fragmented into two fragments; error close, code 1002" },

	--== 6.11 UTF8 Handling, Valid UTF-8 with zero payload fragments

	--[[
	{ index='107', id='6.11.1', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='108', id='6.11.2', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='109', id='6.11.3', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='110', id='6.11.4', desc="send ping fragmented into two fragments; error close, code 1002" },
	{ index='111', id='6.11.5', desc="send ping fragmented into two fragments; error close, code 1002" },
--]]


	--== 7.1 Close behavior, basic

	--[[
	--]]
	{ index='210', id='7.1.1', desc="Send a message followed by a close frame" },
	{ index='211', id='7.1.2', desc="Send two close frames" },
	{ index='212', id='7.1.3', desc="Send a ping after close message" },
	{ index='213', id='7.1.4', desc="Send text message after sending a close frame" },
	{ index='214', id='7.1.5', desc="Send message fragment1 followed by close then fragment" },
	{ index='215', id='7.1.6', desc="Send 256K message followed by close then a ping" },

	--== 7.3 Close behavior, close frame structure, payload length

	--[[
	--]]
	{ index='216', id='7.3.1', desc="Send a close frame with payload length 0 (no close code, no close reason)" },
	{ index='217', id='7.3.2', desc="Send a close frame with payload length 1" },
	{ index='218', id='7.3.3', desc="Send a close frame with payload length 2 (regular close with a code)" },
	{ index='219', id='7.3.4', desc="Send a close frame with close code and close reason" },
	{ index='220', id='7.3.5', desc="Send a close frame with close code and close reason of maximum length (123)" },
	{ index='221', id='7.3.6', desc="Send a close frame with close code and close reason which is too long (124) - total frame payload 126 octets" },

	--== 7.5 Close behavior, close frame structure, payload value

	-- { index='222', id='7.5.1', desc="Send a close frame with invalid UTF8 payload" },

	--== 7.7 Close behavior, close frame structure, valid close codes

	--[[
	--]]
	{ index='223', id='7.7.1', desc="Send close with valid close code 1000" },
	{ index='224', id='7.7.2', desc="Send close with valid close code 1001" },
	{ index='225', id='7.7.3', desc="Send close with valid close code 1002" },
	{ index='226', id='7.7.4', desc="Send close with valid close code 1003" },
	{ index='227', id='7.7.5', desc="Send close with valid close code 1007" },
	{ index='228', id='7.7.6', desc="Send close with valid close code 1008" },
	{ index='229', id='7.7.7', desc="Send close with valid close code 1009" },
	{ index='230', id='7.7.8', desc="Send close with valid close code 1010" },
	{ index='231', id='7.7.9', desc="Send close with valid close code 1011" },
	{ index='232', id='7.7.10', desc="Send close with valid close code 3000" },
	{ index='233', id='7.7.11', desc="Send close with valid close code 3999" },
	{ index='234', id='7.7.12', desc="Send close with valid close code 4000" },
	{ index='235', id='7.7.13', desc="Send close with valid close code 4999" },

	--== 7.9 Close behavior, close frame structure, invalid close codes

	--[[
	--]]
	{ index='236', id='7.9.1', desc="Send close with invalid close code 0" },
	{ index='237', id='7.9.2', desc="Send close with invalid close code 999" },
	{ index='238', id='7.9.3', desc="Send close with invalid close code 1004" },
	{ index='239', id='7.9.4', desc="Send close with invalid close code 1005" },
	{ index='240', id='7.9.5', desc="Send close with invalid close code 1006" },
	{ index='241', id='7.9.6', desc="Send close with invalid close code 1012" },
	{ index='242', id='7.9.7', desc="Send close with invalid close code 1013" },
	{ index='243', id='7.9.8', desc="Send close with invalid close code 1014" },
	{ index='244', id='7.9.9', desc="Send close with invalid close code 1015" },
	{ index='245', id='7.9.10', desc="Send close with invalid close code 1016" },
	{ index='246', id='7.9.11', desc="Send close with invalid close code 1100" },
	{ index='247', id='7.9.12', desc="Send close with invalid close code 2000" },
	{ index='248', id='7.9.13', desc="Send close with invalid close code 2999" },

	--== 7.13 Close behavior, Informational close information

	--[[
	--]]
	{ index='249', id='7.13.1', desc="Send close with close code 5000" },
	{ index='250', id='7.13.2', desc="Send close with close code 65536" },


	--== 9.1 Limits/Performance, text message

	--[[
	--]]
	{ index='251', id='9.1.1', desc="Send text message message with payload of length 64 * 2**10 (64k)" },
	-- { index='252', id='9.1.2', desc="Send text message message with payload of length 256 * 2**10 (256k)." },
	-- { index='253', id='9.1.3', desc="Send text message message with payload of length 1 * 2**20 (1M)" },
	-- { index='254', id='9.1.4', desc="Send text message message with payload of length 4 * 2**20 (4M)." },
	-- { index='255', id='9.1.5', desc="Send text message message with payload of length 8 * 2**20 (8M)" },
	-- { index='256', id='9.1.6', desc="Send text message message with payload of length 16 * 2**20 (16M)." },


	--== 9.2 Limits/Performance, binary message

	-- binary not yet supported
	-- { index='257', id='9.2.1', desc="Send binary message message with payload of length 64 * 2**10 (64k" },
	-- 257-9.2.1
	-- 258-9.2.2
	-- 259-9.2.3
	-- 260-9.2.4
	-- 261-9.2.5
	-- 262-9.2.6

	--== 9.3 Limits/Performance, fragmented text message

	-- { index='263', id='9.3.1', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 64" },
	-- { index='264', id='9.3.2', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 256" },
	-- { index='265', id='9.3.3', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 1k" },
	-- { index='266', id='9.3.4', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 4k" },
	-- { index='267', id='9.3.5', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 16k" },
	-- { index='268', id='9.3.6', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 64k" },
	-- { index='269', id='9.3.7', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 256k" },
	-- { index='270', id='9.3.8', desc="Send fragmented text message message with message payload of length 4 * 2**20 (4M). Sent out in fragments of 1M" },
	-- { index='271', id='9.3.9', desc="Send fragmented text message message with message payload of length 4 * 2**20 (8M). Sent out in fragments of 4M" },

	--== 9.4 Limits/Performance, fragmented binary message

	-- 272-9.4.1
	-- 273-9.4.2
	-- 274-9.4.3
	-- 275-9.4.4
	-- 276-9.4.5
	-- 277-9.4.6
	-- 278-9.4.7
	-- 279-9.4.8
	-- 280-9.4.9

	--== 9.5 Limits/Performance, text message

	-- { index='281', id='9.5.1', desc="Send text message message with payload of length 1 * 2**20 (1M). Sent out data in chops of 64 octets" },
	-- 281-9.5.1
	-- 282-9.5.2
	-- 282-9.5.3
	-- 284-9.5.4
	-- 285-9.5.5
	-- { index='286', id='9.5.6', desc="Send text message message with payload of length 1 * 2**20 (1M). Sent out data in chops of 2048 octets" },

	--== 9.6 Limits/Performance, binary message

	-- BINARY NOT YET SUPPORTED

	-- { index='287', id='9.6.1', desc="Send binary message message with payload of length 1 * 2**20 (1M). Sent out data in chops of 64 octets" },
	-- 288-9.6.2
	-- 289-9.6.3
	-- 290-9.6.4
	-- 291-9.6.5
	-- 292-9.6.6

	--== 9.7 Limits/Performance, text message roundtrip time

	--[[
	{ index='293', id='9.7.1', desc="Send 1000 text messages of payload size 0 to measure implementation/network RTT (round trip time) / latency" },
	{ index='297', id='9.7.5', desc="Send 1000 text messages of payload size 256 to measure implementation/network RTT (round trip time) / latency" },
	--]]
	-- { index='294', id='9.7.2', desc="Send 1000 text messages of payload size 16 to measure implementation/network RTT (round trip time) / latency" },
	-- { index='295', id='9.7.3', desc="Send 1000 text messages of payload size 64 to measure implementation/network RTT (round trip time) / latency" },
	-- { index='296', id='9.7.4', desc="Send 1000 text messages of payload size 256 to measure implementation/network RTT (round trip time) / latency" },
	-- { index='298', id='9.7.6', desc="Send 1000 text messages of payload size 256 to measure implementation/network RTT (round trip time) / latency" },

	--== 9.8 Limits/Performance, binary message roundtrip time

	-- BINARY NOT YET SUPPORTED

	-- { index='299', id='9.8.1', desc="Send 1000 binary messages of payload size 0 to measure implementation/network RTT (round trip time) / latency" },
	-- 300-9.6.2
	-- 301-9.6.3
	-- 302-9.6.4
	-- 303-9.6.5
	-- 304-9.6.6


	--== 10.1 Misc, Auto fragmentation

	--[[
	--]]
	{ index='305', id='10.1.1', desc="Send text message with payload of length 65536 auto-fragmented with autoFragmentSize = 1300" },


}


return test_cases

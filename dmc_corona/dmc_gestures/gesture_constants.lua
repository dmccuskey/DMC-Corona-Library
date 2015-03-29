--====================================================================--
-- dmc_corona/dmc_gesture/gesture_constants.lua
--
-- Documentation: http://docs.davidmccuskey.com/dmc-gestures
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2015 David McCuskey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Corona Library : Gesture Constants
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Corona Library : Module Constants
--====================================================================--



--====================================================================--
--== Constants
--====================================================================--


local Constant = {}



--======================================================--
-- Module


-- maximum time to make a change after first press
Constant.FAIL_TIMEOUT = 300

-- used for several things
Constant.GESTURE_TIMEOUT = 300


--======================================================--
-- Long Press Gesture

Constant.TYPE_LONGPRESS = 'longpress'

--== Defaults

Constant.LONGPRESS_ACCURACY = 10
Constant.LONGPRESS_DURATION = 500
Constant.LONGPRESS_TAPS = 0
Constant.LONGPRESS_TOUCHES = 1


--======================================================--
-- Pan Gesture

Constant.TYPE_PAN = 'pan'

--== Defaults

Constant.PAN_THRESHOLD = 10
Constant.PAN_TOUCHES = 1


--======================================================--
-- Pinch Gesture

Constant.TYPE_PINCH = 'pinch'

--== Defaults

Constant.PINCH_RESET_SCALE = true
Constant.PINCH_THRESHOLD = 5


--======================================================--
-- Tap Gesture

Constant.TYPE_TAP = 'tap'

--== Defaults

Constant.TAP_ACCURACY = 10
Constant.TAP_TAPS = 1
Constant.TAP_TOUCHES = 1




return Constant

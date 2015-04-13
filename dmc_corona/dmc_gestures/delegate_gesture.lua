--====================================================================--
-- dmc_corona/dmc_gestures/delegate_gesture.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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
--== DMC Corona UI : Gesture Recognizer Delegate
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--- Gesture Recognizer Delegate Interface.
-- the interface for controlling a Gesture Recognizer via a delegate. currently all methods are optional, only implement if needed.
--
-- @classmod Delegate.GestureRecognizer
-- @usage
-- local Gesture = require 'dmc_corona.dmc_gestures'
--
-- -- setup delegate object
-- local delegate = {
--   shouldRecognizeWith=function(self, did_recognize, to_fail )
--     return true
--   end,
-- }
-- @usage
-- local widget = dUI.newPanGesture()
-- widget.delegate = <delgate object>
-- @usage
-- local Gesture = require 'dmc_corona.dmc_gestures'
-- local widget = dUI.newPanGesture{
--   delegate=<delegate object>
-- }



--- (optional) asks delegate if Gesture Recognizer should remain active.
-- return true if Gesture Recognizer should remain, the default return value is `false`.
--
-- @within Methods
-- @function :shouldRecognizeWith
-- @tparam object did_recognize Gesture Recognizer which has Recognized its gesture
-- @tparam object to_fail Gesture Recognizer which is about to be Failed
-- @treturn bool true if Gesture Recognizer `to_fail` should remain.




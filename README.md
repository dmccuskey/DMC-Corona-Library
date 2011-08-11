# Overview #

The DMC Corona Library is a collection of classes and utilities for use with Lua and Corona SDK.


Library Documentation: http://docs.davidmccuskey.com/display/docs/DMC+Corona+Library



## Current Files ##


### dmc_objects.lua ###

This file contains several object classes which can be used as the top-most class when doing object-oriented programming in Lua and the Corona SDK.
When doing OOP, this class provides:

* a simple structure for doing OOP in Lua and Corona SDK
* optimizations to speed up property access on objects
* superClass() and superCall() functions to access super classes and methods
* object printing support
* an API similar to Corona objects

Documentation: http://docs.davidmccuskey.com/display/docs/dmc_objects.lua

_There are several examples in the folder 'examples/dmc_objects/' which show how to setup OOP structures in Lua. There are even several original Corona examples modified to be object oriented - this makes it easy to see how to move to an OOP style of programming._


### dmc_buttons.lua ###

This file contains classes to create different types of graphical buttons and button groups. It can create:

* a Push button with optional text label
* a Radio/Toggle button (on/off state) with optional text label
* Toggle Group which allows either none or one selection of a group of buttons
* Radio Group which allows single selection of a group of buttons

Documentation: http://docs.davidmccuskey.com/display/docs/dmc_buttons.lua


_The code in this file is also great if you're looking for an example of multi-level class inheritance in Lua._


### dmc_utils.lua ###

This file is a small, but growing list of helpful utility functions. At the moment they are mostly concerned with tables.
It provides these functions:

* extend() - similar to jQuery extend()
* hasOwnProperty() - similar to JavaScript hasOwnProperty
* propertyIn() - check property existence in a list
* destroy() - generic table destruction
* print() - multi-level object printing

Documentation: http://docs.davidmccuskey.com/display/docs/dmc_utils.lua


## License ##

(The MIT License)

Copyright (C) 2011 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
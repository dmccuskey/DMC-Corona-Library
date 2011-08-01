# Overview #

The DMC Corona Library is a collection of classes and utilities for use with Lua and Corona SDK.


Library Documentation: http://docs.davidmccuskey.com/display/docs/DMC+Corona+Library



## Current Files ##


### dmc_object.lua ###

This file contains the base class Object which is intended to be used as the top-most class when doing object oriented programming in Lua and the Corona SDK.
When doing OOP, this class provides:

* simple structure to help organize code and facilitate optimizations when doing OOP in Lua and the Corona SDK
* super() and superCall() functions to access super classes and methods
* object printing support
* an API similar to Corona objects

Documentation: http://docs.davidmccuskey.com/display/docs/dmc_object.lua


### dmc_buttons.lua ###

This file contains classes to create different types of graphical buttons and button groups. It can create:

* a Push button with optional text label
* a Radio/Toggle button (on/off state) with optional text label
* Toggle Group which allows either none or one selection of a group of buttons
•* Radio Group which allows single selection of a group of buttons

Documentation: http://docs.davidmccuskey.com/display/docs/dmc_buttons.lua


### dmc_utils.lua ###

This file is a small, but growing list of helpful utility functions. At the moment they are mostly concerned with tables.
It provides these functions:

* extend() - similar to jQuery extend()
* hasOwnProperty() - similar to JavaScript hasOwnProperty
* propertyIn() - check property existence in a list
* destroy() - generic table destruction
* print() - multi-level object printing

Documentation: http://docs.davidmccuskey.com/display/docs/dmc_utils.lua
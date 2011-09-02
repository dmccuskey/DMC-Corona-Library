# Overview #

The DMC Corona Library is a collection of classes and utilities for use with Lua and Corona SDK.


Library Documentation: http://docs.davidmccuskey.com/display/docs/DMC+Corona+Library



## Current Files ##



### dmc_objects.lua ###

This file contains several methods and object classes which together form an object-oriented framework to use when programming in Lua with Corona SDK.  _**Though it's not just for Corona - the top-level object classes can be used when developing software in plain Lua.**_

When doing OOP, these classes provide:

* **a classical model of object oriented programming**

	`dmc_objects` is structured after the classical inheritance model, thus is easy to learn and use by people with varying levels of experience. This also helps give a solid organizational structure when using a language that is relatively unstructured.

* **a simple structure for doing OOP in Lua and Corona SDK**

	The framework also abstracts the details of doing inheritance in Lua so that both experienced and inexperienced users of the language can focus on the code being written, and not the gory details of the language. There is no need to learn about Lua `metatables` until you want to know. All of that is taken care of so you can get things done.

* **fast execution through structure and optimizations**

	Because of the way Lua performs lookups for properties and methods, there can be a small performance penalty when using objects with many levels of inheritance. The solution is to get an object's properties and methods as close to the object as possible (ie, ON the object). This framework does this for you so you can get the execution speed without having to sacrifice the benefit of code organization provided by objects.

* **a mechanism for getters and setters**

	The object model in `dmc_objects` was built to provide getters and setters in your object classes ! Go ahead, you can say it, "Yay, getters and setters !!!"

* **superClass() and superCall()**

	Among other object-related methods, `dmc_objects` has `superClass()` to access an object's parent, and `superCall()` allows you to call an overridden method on a super class !

* **an API similar to Corona display objects**

	The core Corona Object API and Corona Physics Body API have been added to the pertinent base classes in `dmc_objects`. This allows you to treat your objects as if they were native Corona Display Objects &dagger;.

* **object printing support**

	There is flexible, built-in support to print objects during debugging.


&dagger; You can treat them like Corona objects 99.5% of the time. Don't worry, the other 0.5% of the time is easy to understand. :)


**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/Quick+Guide+-+dmc_objects

Main Docs: http://docs.davidmccuskey.com/display/docs/dmc_buttons+Documentation

API: http://docs.davidmccuskey.com/display/docs/dmc_objects.lua


**Examples**

There are several examples in the folder 'examples/dmc_objects/' which show how to setup OOP structures in Lua. Among these are some original Corona examples which have been modified to use `dmc_objects` and fit into an OOP style of programming. This will make it easy to see how to move your projects to be object-oriented as well.




### dmc_buttons.lua ###

This file contains classes to create different types of graphical buttons and button groups. It can create:

* a Push button with optional text label
* a Radio/Toggle button (on/off state) with optional text label
* Toggle Group which allows either none or one selection of a group of buttons
* Radio Group which allows single selection of a group of buttons


_The code in this file is also great if you're looking for an example of multi-level class inheritance in Lua. If you want an easier example of multi-level inheritance, see `examples/dmc_objects/DMC-Multishapes/`._


**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/Quick+Guide+-+dmc_buttons

Main Docs: http://docs.davidmccuskey.com/display/docs/dmc_buttons+Documentation

API: http://docs.davidmccuskey.com/display/docs/dmc_buttons.lua


**Examples**

There are several examples in the folder 'examples/dmc_objects/' which show examples of how to use the `dmc_buttons` library.




### dmc_utils.lua ###

This file is a small, but growing list of helpful utility functions. At the moment they are mostly concerned with tables.
It provides these functions:

* extend() - copy one table into another ( similar to jQuery extend() )
* hasOwnProperty() - check if a property is directly on an object ( similar to JavaScript hasOwnProperty )
* propertyIn() - check property existence in a list
* destroy() - generic table destruction
* createObjectCallback() - create a callback closure to call _any_ method on your object
* print() - multi-level object printing


**Documentation**

API: http://docs.davidmccuskey.com/display/docs/dmc_utils.lua



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
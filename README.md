# Overview #

The DMC Corona Library is a collection of classes and utilities for use with Lua and Corona SDK.


Main Library Documentation: http://docs.davidmccuskey.com/display/docs/DMC+Corona+Library



## Current Modules ##

* [dmc_autostore](#dmc_autostore)

  Automatic JSON storage for your app. [read more...](#dmc_autostore)

* [dmc_trajectory](#dmc_trajectory)

  Have objects follow a ballistic trajectory. [read more...](#dmc_trajectory)


<a name="dmc_autostore"></a>
### Module: dmc_autostore ###

This module contains a data-storage manager which makes saving application data painlessly easy simply because it doesn't have an API! Instead, any modifications which you make to your data structure will trigger the save mechanism. Super simple!!

`dmc_autostore` has these features:

* **allows saving of structured data (ie, JSON), not just key/value pairs**

	Saving application or game data can get ugly with key/value storage. `dmc_autostore` saves data with a flexible JSON structure which can be modified on-the-fly.

* **simplicity in data storage -- there is NO API !!**

	`dmc_autostore` saves modifications to data *automatically*. There is no API to learn in order to load or save data. Any change to your data structure will trigger the save mechanism.

* **AutoStore is configurable**

	There are several parameters available to configure, the most important are the two timers which regulate how quickly data modifications will be written to storage.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_autostore.lua


**Examples**

There is a detailed example in the folder `examples/dmc_autostore/` which shows how to use the `dmc_autostore` library.



### Module: dmc_kolor ###

`dmc_kolor` is a Lua module which brings back the traditional ways of describing colors using RGBA values ( eg, 255, 180, 34 ) instead of the new way using percentage values (eg, 1, .5, .25 ) brought about by the change to Graphics 2.0.

It also gives additional functionality like the ability to use names when setting object colors like "Aqua" or "Red". The module even includes color tables for all of the X11 color definitions.

[more info...](dmc_kolor/)

**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_kolor.lua



### Module: dmc_nicenet ###

`dmc_nicenet` is a Lua module used for communication with a network server. It gets its name because it is meant to help an application be better behaved with its network requests.

It is intended to be a drop-in replacement for the standard Corona Network library, so you automatically get some great benefits without changing any code.

The module will help with:

* **Request Queue**

	A queue ensures that your app won't overrun your server with data requests. You get this for free !

* **Mock Server Hook**

	You can add a mock server for developent and testing. You can get this with slightly modifying your code.

* **Priority**

  You can dynamically set priority for any request still in the queue. All requests can automatically be assigned a default priority value. This is more advanced, so data requests must be written with this in mind.

[more info...](dmc_nicenet/)

**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_nicenet.lua



### dmc_objects.lua ###

This file contains several methods and object classes which together form an object-oriented framework to use when programming in Lua with Corona SDK.  _**Though it's not just for Corona - the top-level object classes can be used when developing software in plain Lua.**_

When doing OOP, these classes provide:

* **a classical model of object oriented programming**

	`dmc_objects` is structured after the classical inheritance model, thus is easy to learn and use by people with varying levels of experience. This also helps give a solid organizational structure when using a language that is relatively unstructured.

* **a simple structure for doing OOP in Lua and Corona SDK**

	The framework also abstracts the details of doing inheritance in Lua so that both experienced and inexperienced users of the language can focus on the code being written, and not the gory details of the language - ie, there is no need to learn about Lua `metatables` until you want to know. All of that is taken care of so you can get things done.

* **fast execution through structure and optimizations**

	Because of the way Lua performs lookups for properties and methods, there can be a small performance penalty when using objects with many levels of inheritance. The solution for this is to get an object's properties and methods as close to the object as possible (ie, ON the object). `dmc_objects` does this for you so you can get the execution speed without having to sacrifice the benefit of code organization provided by object-oriented programming.

* **a mechanism for getters and setters**

	The object model in `dmc_objects` was built to provide getters and setters in your object classes ! Go ahead, you can say it, "Yay, getters and setters !!!"

* **superClass() and superCall()**

	Among other object-related methods, `dmc_objects` has `superClass()` to access an object's parent, and `superCall()` which allows you to call an overridden method on a super class !

* **an API similar to Corona display objects**

	The core Corona Object API and Corona Physics Body API have been added to the pertinent base classes in `dmc_objects`. This allows you to treat your custom objects as if they were native Corona Display Objects &dagger;.

* **object printing support**

	There is flexible, built-in support to print objects during debugging.


&dagger; You can treat them like Corona objects 99.5% of the time. Don't worry, the other 0.5% is easy to understand. :)


**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/Quick+Guide+-+dmc_objects

API: http://docs.davidmccuskey.com/display/docs/dmc_objects.lua

Main Docs: http://docs.davidmccuskey.com/display/docs/dmc_buttons+Documentation


**Examples**

There are several examples in the folder `examples/dmc_objects/` which show how to setup OOP structures in Lua. Among these are some original Corona examples which have been modified to use `dmc_objects` and fit into an OOP style of programming. These will make it easier to see how to move your projects to be object-oriented as well.




### dmc_buttons.lua ###

This file contains classes to create different types of graphical buttons and button groups. It can create:

* a Push button with optional text label
* a Radio/Toggle button (on/off state) with optional text label
* Toggle Group which allows either none or one selection of a group of buttons
* Radio Group which allows single selection of a group of buttons


_The code in this file is also great if you're looking for an example of multi-level class inheritance in Lua. If you want an easier example of multi-level inheritance, see `examples/dmc_objects/DMC-Multishapes/`._


**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/Quick+Guide+-+dmc_buttons

API: http://docs.davidmccuskey.com/display/docs/dmc_buttons.lua

Main Docs: http://docs.davidmccuskey.com/display/docs/dmc_buttons+Documentation


**Examples**

There are examples in the folder `examples/dmc_buttons/` which show how to use the `dmc_buttons` library. Other examples use the button class as well - check in `examples/dmc_objects/`.




### Module dmc_states ###

`dmc_states` is a Lua module which helps to implement the State Machine design pattern.

[more info...](dmc_states/)

**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_states.lua



### dmc_touchmanager.lua ###

This module controls how touch events are processed within an application made with the Corona SDK. Unlike the default (broken?) multi-touch behavior in the Corona SDK, it will allow you to track any amount of events and un/set focus any one of them to or from an object.



**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/Quick+Guide+-+dmc_touchmanager



**Examples**

There are examples in the folder `examples/dmc_touchmanager/` which show how to use the `dmc_touchmanager` library.



<a name="dmc_trajectory"></a>
### Module: dmc_trajectory ###

The main intent of this module is to provide an easy way to have objects follow ballistic trajectories. The library module has a single, simple method to do this, but it also has other methods which can be used to obtain raw trajectory calculations if desired.



**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/Quick+Guide+-+dmc_trajectory



**Examples**

There are examples in the folder `examples/dmc_trajectory/` which show how to use the `dmc_trajectory` library.



### dmc_utils.lua ###

This file is a small, but growing list of helpful utility functions. At the moment they are mostly concerned with tables. It provides these functions:

* extend() - copy one table into another ( similar to jQuery extend() )
* hasOwnProperty() - check if a property is directly on an object ( similar to JavaScript hasOwnProperty )
* propertyIn() - check property existence in a list
* destroy() - generic table destruction
* createObjectCallback() - create a callback closure to call _any_ method on your object
* print() - multi-level object printing


**Documentation**

API: http://docs.davidmccuskey.com/display/docs/dmc_utils.lua


**Examples**

As of yet there are no specific examples for `dmc_utils`, however the other files in this library make use of it. Check them for examples.



## License ##

(The MIT License)

Copyright (C) 2011-2013 David McCuskey. All Rights Reserved.

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

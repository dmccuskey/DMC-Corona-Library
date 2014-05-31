# Overview #

The DMC Corona Library is collection of classes and utilities for use with Lua and Corona SDK. As it has grown, so has their dependency on each other, so it's best to use the library as a single unit.

**Documentation & Examples**

There are examples and documentation available. Look in the `examples` folder for a listing of modules. Each example can be run directly in the Corona SDK. Documentation is online at: [docs.davidmccuskey.com](http://docs.davidmccuskey.com/display/docs/DMC+Corona+Library)

**Questions or Comments**

If you have questions or comments you can either:
* post to the Corona forums: http://forums.coronalabs.com
* send me an email: corona-lib at davidmccuskey com

**Issues**

If you have any issues, please post them here on github: [dmc-corona-library issues](https://github.com/dmccuskey/DMC-Corona-Library/issues)



## Note ##

The huge re-org is complete. I have touched every module in the library and then some. Be careful.

The library folder has been renamed to `dmc_corona`, since one of my new libraries is called `dmc_lua`.



## Installation ##

For easy installation, copy the following items at the root-level of your Corona project:

* The entire `dmc_corona` folder
* `dmc_corona_boot.lua`
* `dmc_corona.cfg`

The library gives a lot of flexibility where it is stored in your project. For more information regarding installation, read more online on how to [install the library](http://docs.davidmccuskey.com/display/docs/Install+the+DMC+Corona+Library).



## Current Modules ##

* [dmc_autostore](#dmc_autostore)

  Automatic JSON storage for your app. [Read more...](#dmc_autostore)

* [dmc_buttons](#dmc_buttons)

  Full-featured button set. [Read more...](#dmc_buttons)

* [dmc_dragdrop](#dmc_dragdrop)

  Quick and powerful drag and drop functionality. [Read more...](#dmc_dragdrop)

* [dmc_facebook](#dmc_facebook)

  A better behaved Facebook connector. [Read more...](#dmc_facebook)

* [dmc_files](#dmc_files)

  Read, parse, or save differenct file data. [Read more...](#dmc_files)

* [dmc_kolor](#dmc_kolor)

  Make Corona SDK G1 code run in G2. [Read more...](#dmc_kolor)

* [dmc_kompatible](#dmc_kompatible)

  Make Corona SDK G1 code run in G2. [Read more...](#dmc_kompatible)

* [dmc_kozy](#dmc_kozy)

  Brings back old Corona G1 functionality and gives new capabilities for G2. [Read more...](#dmc_kozy)

* [dmc_mockserver](#dmc_mockserver)

  Emulate a data server (eg REST) in your app - great for testing, API integration, etc. [Read more...](#dmc_mockserver)

* [dmc_nicenet](#dmc_nicenet)

  Makes client apps behave when sending data requests to the server. [Read more...](#dmc_nicenet)

* [dmc_objects](#dmc_objects)

  Advanced OOP for Lua or the Corona SDK. [Read more...](#dmc_objects)

* [dmc_patch](#dmc_patch)

  Mixin beneficial functionality into the Lua language. [Read more...](#dmc_patch)

* [dmc_performance](#dmc_performance)

  Timed performance testing for your app. [Read more...](#dmc_performance)

* [dmc_sockets](#dmc_sockets)

  Buffered, non-blocking, callback- or event-based socket library for clients. [Read more...](#dmc_sockets)

* [dmc_states](#dmc_states)

  Implement the State Machine design pattern with your objects. [Read more...](#dmc_states)

* [dmc_touchmanager](#dmc_touchmanager)

  True multi-touch capabilities for the Corona SDK. [Read more...](#dmc_touchmanager)

* [dmc_trajectory](#dmc_trajectory)

  Ballistic (parabolic) trajectory for objects. [Read more...](#dmc_trajectory)

* [dmc_utils](#dmc_utils)

  Miscellaneous utility functions for tables, web, etc. [Read more...](#dmc_utils)

* [dmc_wamp](#dmc_wamp)

  WAMP (http://wamp.ws) module for the Corona SDK. [Read more...](#dmc_wamp)

* [dmc_websockets](#dmc_websockets)

  WebSocket module for the Corona SDK. [Read more...](#dmc_websockets)


<a name="dmc_autostore"></a>
### Module: dmc_autostore ###

This module contains a data-storage manager which makes saving application data painlessly easy, simply because it doesn't have an API! Instead, any modifications which you make to your data structure will trigger the save mechanism. Super simple!!

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



<a name="dmc_buttons"></a>
### Module: dmc_buttons ###

This file contains classes to create different types of graphical buttons and button groups. It can create:

* a Push button with optional text label
* a Radio/Toggle button (on/off state) with optional text label
* Toggle Group which allows either none or one selection of a group of buttons
* Radio Group which allows single selection of a group of buttons


_The code in this file is also great if you're looking for an example of multi-level class inheritance in Lua. If you want an easier example of multi-level inheritance, see `examples/dmc_objects/DMC-Multishapes/`._

(this version is deprecated and will be re-written from ground-up for G2. watch dmc-corona-widgets repo)


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_buttons.lua


**Examples**

There are examples in the folder `examples/dmc_buttons/` which show how to use the `dmc_buttons` library.



<a name="dmc_dragdrop"></a>
### Module: dmc_dragdrop ###

Easily incorporate powerful drag and drop functionality into your app.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_dragdrop.lua


**Examples**

There is a detailed example in the folder `examples/dmc_dragdrop/` which shows how to use the `dmc_dragdrop` library.



<a name="dmc_facebook"></a>
### Module: dmc_facebook ###

A better behaved, easier to setup Facebook connector.

* Can be used for kiosk-mode apps (many people using it on one device)

* Easier to setup

* Login flow *doesn't leave application* !


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_facebook.lua


**Examples**

There is a detailed example in the folder `examples/dmc_facebook/` which shows how to use the `dmc_facebook` library.



<a name="dmc_files"></a>
### Module: dmc_files ###

Read and save different files, including JSON, etc.

* Can read in config files, including a customizable format


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_files.lua


**Examples**

There is a detailed example in the folder `examples/dmc_files/` which shows how to use the `dmc_files` library.



### Module: dmc_kolor ###

`dmc_kolor` is a Lua module which brings back the traditional ways of describing colors using RGBA values ( eg, 255, 180, 34 ) instead of the new way using percentage values (eg, 1, .5, .25 ) brought about by the change to Graphics 2.0.

It also gives additional functionality like the ability to use names when setting object colors like "Aqua" or "Red". The module even includes color tables for all of the X11 color definitions.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_kolor.lua



<a name="dmc_kompatible"></a>
### Module: dmc_kompatible ###

A module which allows your legacy Corona Graphics 1.0 code to run in Corona Graphics 2.0.


**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/dmc_kompatible.lua

**Examples**

There are examples in the folder `examples/dmc_kompatible/` which show how to use the `dmc_kompatible` library.



<a name="dmc_kozy"></a>
### Module: dmc_kozy ###

Brings back old Corona G1 functionality and gives new capabilities for G2.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_kozy.lua


**Examples**

There is a detailed example in the folder `examples/dmc_kozy/` which shows how to use the `dmc_kozy` library.



<a name="dmc_mockserver"></a>
### Module: dmc_mockserver ###

Emulate a data server (eg REST) in your app - great for testing, API integration, etc. If you make network requests to servers (and the API isn't ready) then you want this app. You want it anyway !

* Extremely valuable module when building an app while API is being built too.

  Create full network requests ! (images, data, etc) Your app doesn't know the difference. Plus, as the API is completed, you can allow those requests through for integration, while the other requests are still being answered by Mock Server

* Also can emulate slow network connections, which is crucial for testing asyncronous code.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_mockserver.lua


**Examples**

There is a detailed example in the folder `examples/dmc_mockserver/` which shows how to use the `dmc_mockserver` library.



### Module: dmc_nicenet ###

`dmc_nicenet` is a Lua module used for communication with a network server. It gets its name because it is meant to help an application be better behaved with its network requests.

It is intended to be a drop-in replacement for the standard Corona Network library, so you automatically get some great benefits without changing any code.

The module will help with:

* **Request Queue**

	A queue ensures that your app won't overrun your server with data requests. You get this for free !

* **Mock Server Hook**

	You can add a mock server for developent and testing. You can get this by barely modifying your code.

* **Priority**

  You can dynamically set priority for any request still in the queue. All requests can automatically be assigned a default priority value. This is more advanced, so data requests must be written with this in mind.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_nicenet.lua



<a name="dmc_objects"></a>
### Module: dmc_objects ###

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

http://docs.davidmccuskey.com/display/docs/dmc_objects.lua


**Examples**

There are several examples in the folder `examples/dmc_objects/` which show how to setup OOP structures in Lua. Among these are some original Corona examples which have been modified to use `dmc_objects` and fit into an OOP style of programming. These will make it easier to see how to move your projects to be object-oriented as well.



<a name="dmc_performance"></a>
### Module: dmc_performance ###

Timed performance testing for your app.

* Profile methods, functions, library loading, etc. See where your app is slow.

* Prints out memory status, etc.


**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/dmc_performance.lua


**Examples**

There are examples in the folder `examples/dmc_performance/` which show how to use the `dmc_performance` library.



<a name="dmc_sockets"></a>
### Module: dmc_sockets ###

`dmc_sockets` is a buffered, callback- or event-based socket library for clients which has two-flavors of sockets - asyncronous with callbacks or syncronous with events (non-blocking). In reality it's just a thin layer over the built-in socket library *LuaSockets*, but gives several additional benefits for your networking pleasure:

* **Callback- or event-based sockets**

	The event-based socket is more syncronous and the callback-based is asyncronous in nature, but they're both non-blocking. Create that event-based app like you've always wanted to !

* **Dynamic buffer**

	Any data coming in is automatically put into a buffer. At any point you can find out how many bytes are available for reading. Plus, the socket has a method `unreceive()`, which can be used to *put back* data even after it's been read.

* **Re-connectable**

	`dmc_sockets` sockets have additional functionality to easily re-build or re-connect closed or dropped connections. This is unlike ordinary sockets which can't be re-used once they are closed !

* **Socket-Check Throttling**

  How often the module checks for new data is totally configurable. If you want more cycles for your app, then turn up the throttling !


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_sockets.lua


**Examples**

Examples which show how to use the `dmc_sockets` library can be found in the folder `examples/dmc_sockets/`.



<a name="dmc_states"></a>
### Module: dmc_states ###

`dmc_states` is a Lua module which helps to implement the State Machine design pattern. It can be used in Lua projects outside of Corona.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_states.lua



<a name="dmc_touchmanager"></a>
### Module: dmc_touchmanager ###

This module controls how touch events are processed within an application made with the Corona SDK. Unlike the default (broken?) multi-touch behavior in the Corona SDK, it will allow you to track any number of events (up to device limit) and un/set focus any one of them to or from an object.


**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_touchmanager.lua


**Examples**

There are examples in the folder `examples/dmc_touchmanager/` which show how to use the `dmc_touchmanager` library.



<a name="dmc_trajectory"></a>
### Module: dmc_trajectory ###

The main intent of this module is to provide an easy way to have objects follow ballistic trajectories. The library module has a single, simple method to do this, but it also has other methods which can be used to obtain raw trajectory calculations if desired.


**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/dmc_trajectory.lua


**Examples**

There are examples in the folder `examples/dmc_trajectory/` which show how to use the `dmc_trajectory` library.



<a name="dmc_utils"></a>
### Module: dmc_utils ###

This module is an ever-changing list of helpful utility functions. Ever-changing because, over time, some functions have been removed and put into their own modules, eg `dmc_performance`. Here are some of the groupings at the moment:

* Audio Functions - getAudioChannel()
* Callback Functions - createObjectCallback(), getTransitionCompleteFunc()
* Date Functions - calcTimeBreakdown()
* Image Functions - imageScale()
* String Functions - split(), stringFormatting()
* Table Functions - destroy(), extend(), hasOwnProperty(), print(), propertyIn(), removeFromTable(), shuffle(), tableSize(), tableSlice(), tableLength()
copy one table into another ( similar to jQuery extend() )
* Web Functions - parseQuery(), createQuery()


**Documentation**

API: http://docs.davidmccuskey.com/display/docs/dmc_utils.lua


**Examples**

As of yet there are no specific examples for `dmc_utils`, however many of the other `dmc_library` modules make use of it. You can check them for examples.



<a name="dmc_wamp"></a>
### Module: dmc_wamp ###

This module implements WAMP ([Web Application Messaging Protocol](http://wamp.ws))for the Corona SDK.

* Lua module for WAMP _clients_ in Corona SDK
* Supports [WAMP v2](https://github.com/tavendo/WAMP/blob/master/spec/README.md])
* Supports roles `Caller` and `Subscriber`
* Supports TLS (secure WebSocket) (coming soon)
* Supports JSON serializer

**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/dmc_wamp.lua

**Examples**

There are examples in the folder `examples/dmc_wamp/` which show how to use the `dmc_wamp` module.



<a name="dmc_websockets"></a>
### Module: dmc_websockets ###

This module implements WebSockets (RFC6455) for the Corona SDK. With minor modifications it can be used in plain Lua.

* **Follows the web browser API implemenation**

	This makes it very easy to use.

**Documentation**

Quick Guide: http://docs.davidmccuskey.com/display/docs/dmc_websockets.lua

**Examples**

There are examples in the folder `examples/dmc_websockets/` which show how to use the `dmc_websockets` module.





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

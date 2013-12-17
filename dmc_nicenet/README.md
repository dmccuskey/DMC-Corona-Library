### Module: dmc_nicenet ###

`dmc_nicenet` is a Lua module used for communication with a network server. It gets its name because it is meant to help an application be better behaved with its network requests.

It is intended to be a drop-in replacement for the standard Corona Network library, so you automatically get benefits without changing any code.

The modules benefits are:

* **Request Queue**

	A queue ensures that your app won't overrun your server with data requests. You get this for free !

* **Mock Server Hook**

	You can add a mock server for developent and testing. You get this with slightly modifying your code.

* **Priority**

  You can dynamically set priority for any request still in the queue. All requests can automatically be assigned a default priority value. This is more advanced, so data requests must be written with this in mind.

[more info...](dmc_nicenet/)

**Documentation**

http://docs.davidmccuskey.com/display/docs/dmc_nicenet.lua


#### Examples ####

Examples coming soon

#### Documentation ####

http://docs.davidmccuskey.com/display/docs/dmc_states.lua


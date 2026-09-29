# Design Notes

> **Incomplete.** These notes were started in 2011 and never finished. They explain some of the library's choices; the physics notes are about the Corona SDK of that time and may no longer hold in Solar2D.

How the architecture of the DMC libraries came to be.

## Objects and Their Views

The object classes ([dmc-objects](https://github.com/dmccuskey/dmc-objects)' `ComponentBase`) assume that an object will, at some point, be shown on the screen. So each instance gets its own display group, `obj.view`, when it is created: the object's "view", a canvas that its other display objects go into.

An earlier attempt used the display group itself as the base of the object class, but a group couldn't be subclassed so that it still behaved as a pure Solar2D display object; `insert()`, for one, didn't work on a subclass. Keeping the display object inside the object, instead of being it:

- keeps Solar2D's namespaces on the display object separate from the object's own
- leaves the class hierarchy free to take any shape
- gives the object an API to work with its display object, similar to a display object's own

Objects also commonly need to send events to whoever is interested (a button is pressed, a menu item chosen), so every class can listen for and dispatch events. The idea is similar to "code behind" in Adobe Flex.

Objects are set up and torn down in a fixed order of methods, `__init__`, `__createView__`, `__initComplete__` and their `__undo…__` counterparts ([lua-objects](https://github.com/dmccuskey/lua-objects)).

A leading underscore marks a protected or private method or property: don't touch it unless you know what you're doing.

## Modules Without `module()`

The libraries don't use Lua's `module()` function. It's widely considered a poor way to build packages ([LuaModuleFunctionCritiqued](http://lua-users.org/wiki/LuaModuleFunctionCritiqued)), and it isn't needed. Each module is instead a local table that is returned at the end, as is common in JavaScript:

```lua
local M = {}

function M:test1()
end

function M:test2()
end

return M
```

It is simple, easy to understand, and has no "black box" function calls.

## Physics Engine Notes

Collected in 2011 from the Corona forums, while working out how to use the physics engine (Box2D) with display groups. The forum threads are gone.

- **Bodies in different display groups** can collide, but don't move the groups relative to each other: moving a group changes its objects' coordinates relative to the other groups', and collisions between the groups stop working. Keeping all physics bodies in one group avoids this.
- **A display group can't be a physics body.**
- **Custom shapes:** the Corona docs asked for the points in clockwise order, Box2D's manual for counter-clockwise. A shape can have at most 8 points; make a larger one from several shapes.
- **Start physics before adding bodies** with `physics.start()`, and remove every body before calling `physics.stop()`: bodies left in the world could crash the Simulator.
- **Don't change the world during a collision event**, such as adding or removing bodies: do it a moment later, in a timer.
- **Don't reuse a shape's table.** Passing the same table to define two bodies' custom shapes caused "ghost" collisions: a body launched into empty space collided at once, and the screen went black.

# CoffeeClasskit
You can make much more with CoffeeScript classes.

## Why
As of `class ... extends ...` is implemented in coffee with
```coffee
for key of parent
  child[key] = parent[key]  if __hasProp_.call(parent, key)
```
it makes absolutely impossible to define class instance variables.

## Solution
With `classkit.extendsWithProp` default inheritance is redefined using
`child.__proto__ = parent`. So it would not work on engines which
do not support `__proto__`.

Ensure that you call this method before any class properties declarations,
'cause it'll drop'em all.

Once you use `extendsWithProto` you should use it on all descendents.

## Comparison with other libraries

* It doesn't break into global namespace.
* Works on a top of usual coffee-script class declaration.
* Helpers to define ruby-like instance & class variables.
* Full callbacks stack of Ruby-like inheritance model (`included`,
  `append_features`, `extend_object`, etc).
* ActiveSupport's `Concern`-like behaviour is optional.
* Classes uses prototypes chain.
* It works only 'cause of `__proto__`. Some say it's deprecated :)

## Examples
See tests for examples.

## License
BSD
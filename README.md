# CoffeeClasskit
You can make much more with CoffeeScript classes.

## Why
As of `extends` is implemented in coffee with
```coffee
for key of parent
  child[key] = parent[key]  if __hasProp_.call(parent, key)
```
it makes absolutely impossible to define class instance variables.

## Solution
With `classkit.extendsWithProp` default inheritance is redefined using
`child.__proto__ = parent`. So it would not work on engines which do not support
`__proto__`. 

Ensure that you call this method before any class properties declaraction,
'cause it'll drop'em all.

Once you use `extendsWithProto` you should use it on all descendents.

## More
Here is also helpers to define ruby-like instance & class variables.

Instance variables usage requires `extendsWithProto`.

## Examples
See tests for examples.

## License
BSD

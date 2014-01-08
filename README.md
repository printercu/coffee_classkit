# CoffeeClasskit

You can make much more with CoffeeScript classes.

```
npm install coffee_classkit
```

```coffee
classkit = require 'coffee_classkit'

class Child extends Parent
  classkit.extendsWithProto @

# ###
class Mixin extends classkit.Module
  @extendsWithProto().concern()

  @includedBlock: ->
    # will run in context of base class
    @instanceVariable 'test'

  class @ClassMethods
    someClassMethod: ->

  someInstanceMethod: ->

class Base extends classkit.Module
  @extendsWithProto().include Mixin

  @someClassMethod()

(new Base).someInstanceMethod()
```

## Why

`class ... extends ...` is implemented in coffee with

```coffee
for key of parent
  child[key] = parent[key]  if __hasProp_.call(parent, key)
```

It makes inheritance sticky.
* If you modify parent's property it would not be modified in child.
* Properties defined with `Object.defineProperty` would not be inherited.
* ...

## Solution

Use prototype chain for inheritance of class methods.

With `classkit.extendsWithProp @` default inheritance is redefined using
`child.__proto__ = parent`.

Ensure that you call this method before any class properties declarations,
'cause it'll drop'em all.

Once you use `extendsWithProto` you should use it on all descendents.

## Features

* It doesn't break into global namespace.
* Works on a top of usual coffee-script class declaration.
* Classes use prototypes chain.
* Full callbacks stack of Ruby-like inheritance model (`included`,
  `append_features`, `extend_object`, etc).
* Helpers to define ruby-like instance & class variables.
* `ActiveSupport::Concern`-like behaviour is optional.
* It works only 'cause of `__proto__`. Some say it's deprecated :)

## For pure JS
`Classkit.inherit` method provides inheritance that can be used in pure JS:

```js
function Parent() { /* ... */ }
var Child;
Classkit.inherit(Parent, Child = function Child(){ /* ... */ });
```

It uses CoffeeScript's inheritance. Take a look on compiled coffee source
to know how to use `super` properly.

## More examples

See source, tests & [costa](https://github.com/printercu/costa).

## License

BSD

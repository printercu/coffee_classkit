assert    = require 'assert'
classkit  = require '../lib/coffee_classkit'

describe 'coffee_classkit', ->
  describe '#extendsWithProto', ->
    beforeEach ->
      class @A
        @x = -> true
      class @B extends @A
        classkit.extendsWithProto @

    it 'keeps child`s own properties clean', ->
      assert.deepEqual Object.keys(@A), ['x']
      assert.deepEqual Object.keys(@B), ['__super__']
      assert.equal @A.x(), true
      assert.equal @B.x(), true

    it 'sets parent as prototype of ancestor', ->
      assert.deepEqual @B.__proto__, @A

  describe '#instanceVariable', ->
    beforeEach ->
      class @A
        classkit.instanceVariable @, 'x'
        @x = 1
      class @B extends @A
        classkit.extendsWithProto @

    it 'defines getter & setter for non-inheritable property', ->
      assert.equal @A.x, 1
      assert.equal @B.x, undefined
      @B.x = 2
      assert.equal @A.x, 1
      assert.equal @B.x, 2

  describe '#classVariable', ->
    beforeEach ->
      class @A
        classkit.classVariable @, 'x'
        @x = 1
      class @B extends @A
        classkit.extendsWithProto @
      class @C extends @B
        classkit.extendsWithProto @

    it 'allows all descendants have access to single value', ->
      assert.equal @A.x, 1
      assert.equal @B.x, 1
      assert.equal @C.x, 1
      @B.x = 2
      assert.equal @A.x, 2
      assert.equal @B.x, 2
      assert.equal @C.x, 2

  describe '#classAttribute', ->
    beforeEach ->
      class @A
        classkit.classAttribute @, 'attr', 1
      class @B extends @A
        classkit.extendsWithProto @

    it 'makes instances return class attribute`s value', ->
      assert.equal @A.attr,       1
      assert.equal new @A().attr, 1
      @A.attr = 2
      assert.equal @A.attr,       2
      assert.equal new @A().attr, 2

    it 'makes child inherit parent`s attribute value', ->
      assert.equal @B.attr,       1
      assert.equal new @B().attr, 1
      @A.attr = 2
      assert.equal @B.attr,       2
      assert.equal new @B().attr, 2

    it 'allows child to override parent`s value', ->
      @B.attr = 2
      assert.equal @A.attr,       1
      assert.equal new @A().attr, 1
      assert.equal @B.attr,       2
      assert.equal new @B().attr, 2

    it 'allows instance to override class`es attribute', ->
      (a = new @A).attr = 2
      @B.attr = 3
      (b = new @B).attr = 4
      assert.equal @A.attr, 1
      assert.equal a.attr,  2
      assert.equal @B.attr, 3
      assert.equal b.attr,  4

  describe '#appendFeatures', ->
    it 'processes own properties', ->
      class Mixin
        value:  1
        method: -> 2
      class Target
      classkit.appendFeatures Mixin, Target

      assert.equal Target::value, Mixin::value
      assert.equal Target::method, Mixin::method

    it 'processes properties defined with Object.defineProperty', ->
      class Mixin
      Object.defineProperty Mixin::, 'prop', get: (->), set: (val) ->
      class Target
      classkit.appendFeatures Mixin, Target

      assert.deepEqual Object.getOwnPropertyDescriptor(Target::, 'prop'),
        Object.getOwnPropertyDescriptor(Mixin::, 'prop')

    it 'works with mixins that extends other mixins', ->
      class Mixin
        value:  1
        method: -> 2
      Object.defineProperty Mixin::, 'prop', get: (->), set: (val) ->
      class ChildMixin extends Mixin
      # classkit.extendsWithProto ChildMixin
      class Target
      classkit.appendFeatures ChildMixin, Target

      assert.equal Target::value, Mixin::value
      assert.equal Target::method, Mixin::method
      assert.deepEqual Object.getOwnPropertyDescriptor(Target::, 'prop'),
        Object.getOwnPropertyDescriptor(Mixin::, 'prop')

  describe '#extendObject', ->

  describe '#include', ->

  describe '#findOptions', ->
    opts  = opts: 'opts'
    val1  = 'val1'
    val2  = 'val2'
    val3  = val: 'val'

    before ->
      @find = classkit.findOptions

    it 'returns [{}, []] if nothing is given', ->
      assert.deepEqual @find(), [{}, []]

    it 'returns [{}, []] if empty array is given', ->
      assert.deepEqual @find([]), [{}, []]

    it 'works if input array has one element', ->
      assert.deepEqual @find([opts]), [opts, []]
      assert.deepEqual @find([val1]), [{},   [val1]]

    it 'works if input array has two elements', ->
      assert.deepEqual @find([opts, val1]), [opts, [val1]]
      assert.deepEqual @find([val1, opts]), [opts, [val1]]
      assert.deepEqual @find([val1, val2]), [{},   [val1, val2]]

    it 'works if input array has more elements', ->
      assert.deepEqual @find([opts, val1, val2]), [opts, [val1, val2]]
      assert.deepEqual @find([val1, val2, opts]), [opts, [val1, val2]]
      assert.deepEqual @find([val1, val3, val2]), [{},   [val1, val3, val2]]

    it 'returns last element as options if first is an object too', ->
      assert.deepEqual @find([val3, val1, opts]), [opts, [val3, val1]]

    it 'works with arguments object', ->
      f = => @find arguments
      assert.deepEqual f(), [{}, []]
      assert.deepEqual f(opts), [opts,  []]
      assert.deepEqual f(val1), [{},    [val1]]
      assert.deepEqual f(opts, val1, val2), [opts, [val1, val2]]
      assert.deepEqual f(val1, val2, opts), [opts, [val1, val2]]

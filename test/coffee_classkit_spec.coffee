assert    = require 'assert'
classkit  = require '../'

testBasicInheritance = ->
  it 'keeps child`s own properties clean', ->
    assert.deepEqual Object.keys(@Parent), ['x']
    assert.deepEqual Object.keys(@Child), ['__super__']
    assert.equal @Parent.x(), true
    assert.equal @Child.x(), true

  it 'sets parent as prototype of ancestor', ->
    assert.deepEqual @Child.__proto__, @Parent

describe 'coffee_classkit', ->
  describe '#extendsWithProto', ->
    beforeEach ->
      class @Parent
        @x = -> true
      class @Child extends @Parent
        classkit.extendsWithProto @

    testBasicInheritance()

    it 'runs _inherited_ hook', ->
      class X
        @inherited = (subclass) ->
          assert.equal @, X
          assert.equal subclass.xattr, X.xattr
          subclass.yattr = true

        @xattr: {a: 1}

      class Y extends X
        classkit.extendsWithProto @

      assert.equal X.yattr, null
      assert Y.yattr


  describe '#instanceVariable', ->
    beforeEach ->
      class @A
        classkit.instanceVariable @, 'x'
      class @B extends @A
        classkit.extendsWithProto @

    it 'defines attr which is undefined', ->
      assert.equal @A.x, undefined

    it 'defines getter & setter for non-inheritable property', ->
      @A.x = 1
      assert.equal @A.x, 1
      assert.equal @B.x, undefined
      @B.x = 2
      assert.equal @A.x, 1
      assert.equal @B.x, 2

  describe '#classVariable', ->
    beforeEach ->
      class @A
        classkit.classVariable @, 'x'
      class @B extends @A
        classkit.extendsWithProto @
      class @C extends @B
        classkit.extendsWithProto @

    it 'defines attr which is undefined', ->
      assert.equal @A.x, undefined

    it 'allows all descendants have access to single value', ->
      @A.x = 1
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
        classkit.classAttribute @, 'attr'
        @attr = 1
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
    it 'calls mixin`s ::appendFeatures', ->
      class Mixin
        @appendFeatures: (base) ->
          assert.equal @, Mixin
          base.x = 1

        y: 2

      class Base
      classkit.include Base, Mixin

      assert.equal Base.x, 1
      assert.equal Base::x, null
      assert.equal Base.y, null
      assert.equal Base::y, null

  describe '#extend', ->
    it 'calls mixin`s ::extendObject', ->
      class Mixin
        @extendObject: (base) ->
          assert.equal @, Mixin
          base::x = 1

        y: 2

      class Base
      classkit.extend Base, Mixin

      assert.equal Base.x, null
      assert.equal Base::x, 1
      assert.equal Base.y, null
      assert.equal Base::y, null

  describe '::inherit', ->
    beforeEach ->
      @Parent = ->
      @Parent.x = -> true
      classkit.inherit @Parent, @Child = ->

    testBasicInheritance()

    it 'runs _inherited_ hook', ->
      X = ->
      X.inherited = (subclass) ->
        assert.equal @, X
        assert.equal subclass.xattr, X.xattr
        subclass.yattr = true

      X.xattr = a: 1

      classkit.inherit X, Y = ->

      assert.equal X.yattr, null
      assert Y.yattr

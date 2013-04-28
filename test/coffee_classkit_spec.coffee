assert    = require 'assert'
classkit  = require '../coffee_classkit'

describe 'coffee_classkit', ->
  describe '#extendsWithProto', ->
    it 'should keep child`s own properties clean', ->
      class A
        @x = -> true
      class B extends A
        classkit.extendsWithProto @

      assert.deepEqual Object.keys(A), ['x']
      assert.deepEqual Object.keys(B), ['__super__']
      assert.equal A.x(), true
      assert.equal B.x(), true

  describe '#instanceVariable', ->
    it 'should define getter & setter for non-inheritable property', ->
      class A
        classkit.instanceVariable @, 'x'
        @x = 1
      class B extends A
        classkit.extendsWithProto @

      assert.equal A.x, 1
      assert.equal B.x, undefined
      B.x = 2
      assert.equal A.x, 1
      assert.equal B.x, 2

  describe '#classVariable', ->
    it 'after defined all descendents have access to single value', ->
      class A
        classkit.classVariable @, 'x'
        @x = 1
      class B extends A
        classkit.extendsWithProto @
      class C extends B
        classkit.extendsWithProto @

      assert.equal A.x, 1
      assert.equal B.x, 1
      assert.equal C.x, 1
      B.x = 2
      assert.equal A.x, 2
      assert.equal B.x, 2
      assert.equal C.x, 2

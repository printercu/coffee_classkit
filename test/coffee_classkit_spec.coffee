assert    = require 'assert'
classkit  = require '../lib/coffee_classkit'

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

  describe '#findOptions', ->
    opts  = opts: 'opts'
    val1  = 'val1'
    val2  = 'val2'
    val3  = val: 'val'

    it 'should return [{}] if nothing or empty array is given', ->
      assert.deepEqual classkit.findOptions(), [{}]
      assert.deepEqual classkit.findOptions([]), [{}]

    it 'should work if input array has one element', ->
      assert.deepEqual classkit.findOptions([opts]), [opts]
      assert.deepEqual classkit.findOptions([val1]), [{}, val1]

    it 'should work if input array has two elements', ->
      assert.deepEqual classkit.findOptions([opts, val1]), [opts, val1]
      assert.deepEqual classkit.findOptions([val1, opts]), [opts, val1]

    it 'should work if input array has more elements', ->
      assert.deepEqual classkit.findOptions([opts, val1, val2]), [opts, val1, val2]
      assert.deepEqual classkit.findOptions([val1, val2, opts]), [opts, val1, val2]
      assert.deepEqual classkit.findOptions([val1, val3, val2]), [{}, val1, val3, val2]

    it 'last element is more preferable as options', ->
      assert.deepEqual classkit.findOptions([val3, val1, opts]), [opts, val3, val1]

assert    = require 'assert'
classkit  = require '../lib/coffee_classkit'
Callbacks = require '../lib/callbacks'

describe 'Callbacks', ->
  beforeEach ->
    class @Parent extends classkit.Module
      @include Callbacks

      @defineCallbacks 'test'

      constructor: (@runs = []) ->

      test: (callback) ->
        @runs.push 'test'
        callback null

  describe '.runCallbacks', ->
    it 'runs before-callbacks', (done) ->
      @Parent.setCallback 'test', 'before', (err, callback) ->
        @runs.push 'before'
        callback null
      @Parent.setCallback 'test', 'before', (err, callback) ->
        @runs.push 'before2'
        callback null
      new @Parent().runCallbacks 'test', ->
        assert.deepEqual @runs, ['before', 'before2']
        done()

    it 'runs after-callbacks', (done) ->
      @Parent.setCallback 'test', 'after', (err, callback) ->
        @runs.push 'after'
        callback null
      @Parent.setCallback 'test', 'after', (err, callback) ->
        @runs.push 'after2'
        callback null
      new @Parent().runCallbacks 'test',
        (err, callback) ->
          @test callback
        final: (err) ->
          assert.deepEqual @runs, ['test', 'after', 'after2']
          done()

  describe '.skipCallback', ->
    it 'skips callback', (done) ->
      @Parent.setCallback 'test', 'before', (err, callback) ->
        @runs.push 'before'
        callback()
      @Parent.setCallback 'test', 'before', before2 = (err, callback) ->
        @runs.push 'before2'
        callback()
      @Parent.skipCallback 'test', 'before', before2
      new @Parent().runCallbacks 'test', ->
        assert.deepEqual @runs, ['before']
        done()

  describe 'when options are given', ->
    it 'passes `error` & `final` through to flow', (done) ->
      error_callback = 'error_method'
      final_callback = 'final_method'
      new @Parent().runCallbacks 'test',
        (callback) ->
          assert.equal callback.options.error, error_callback
          assert.equal callback.options.final, final_callback
          done()
        error: error_callback
        final: final_callback

    it 'sets `final` to options value if not-object is given', (done) ->
      new @Parent().runCallbacks 'test',
        (callback) -> callback()
        (err, callback) -> done assert.equal err, null

    it 'sets `error` to options value if not-object is given', (done) ->
      new @Parent().runCallbacks 'test',
        (callback) -> callback 'err'
        (err, callback) -> done assert.equal err, 'err'

  describe 'when conditions are given', ->
    beforeEach ->
      @Parent::condition = ->
        @runs.push 'condition'
        true

      @Parent::condition2 = ->
        @runs.push 'condition2'
        false

    describe '`if`', ->
      it 'evaluates conditions in the instance context', (done) ->
        @Parent.setCallback 'test', 'before', if: '@condition()', (err, callback) ->
          @runs.push 'before'
          callback()
        @Parent.setCallback 'test', 'before', if: '@condition2()', (err, callback) ->
          @runs.push 'before2'
          callback()
        new @Parent().runCallbacks 'test', ->
          assert.deepEqual @runs, ['condition', 'before', 'condition2']
          done()

    describe '`unless`', ->
      it 'evaluates conditions in the instance context', (done) ->
        @Parent.setCallback 'test', 'before', unless: '@condition()', (err, callback) ->
          @runs.push 'before'
          callback()
        @Parent.setCallback 'test', 'before', unless: '@condition2()', (err, callback) ->
          @runs.push 'before2'
          callback()
        new @Parent().runCallbacks 'test', ->
          assert.deepEqual @runs, ['condition', 'condition2', 'before2']
          done()

    describe '.skipCallback', ->
      beforeEach ->
        @Parent.setCallback 'test', 'before', if: '@condition()', @before = (err, callback) ->
          @runs.push 'before'
          callback null
        @Parent.setCallback 'test', 'before', unless: '@condition2()', @before2 = (err, callback) ->
          @runs.push 'before2'
          callback null

      it 'does not skip on false conditions', (done) ->
        @Parent.skipCallback 'test', 'before', @before, if: 'false'
        @Parent.skipCallback 'test', 'before', @before2, unless: '@condition()'
        new @Parent().runCallbacks 'test', ->
          assert.deepEqual @runs, ['condition', 'before', 'condition', 'condition2', 'before2']
          done()

      it 'skips on truly conditions', (done) ->
        @Parent.skipCallback 'test', 'before', @before, if: 'true'
        @Parent.skipCallback 'test', 'before', @before2, unless: '@condition2()'
        new @Parent().runCallbacks 'test', ->
          assert.deepEqual @runs, ['condition', 'condition2']
          done()

assert    = require 'assert'
classkit  = require '../../lib/coffee_classkit'

ActionController  = require '../../lib/action_controller'

describe 'ActionController', ->
  describe '#process', ->
    beforeEach ->
      class @TestController extends ActionController
        @extendsWithProto()

        indexAction: (callback) ->
          @runs.push 'index'
          callback()
        
      @controller = new @TestController
      @controller.action = 'index'
      @controller.runs = []

    it 'runs before-callbacks', (done) ->
      @TestController.beforeFilter (callback) ->
        @runs.push 'before'
        callback()
      @controller.process 'indexAction', =>
        assert.deepEqual @controller.runs, ['before', 'index']
        done()

    it 'runs after-callbacks', (done) ->
      @TestController.afterFilter (callback) ->
        assert.deepEqual @runs, ['index']
        done()
      @controller.process 'indexAction', (callback) ->
        throw new Error 'Should not run this callback'

    it 'runs all callbacks', (done) ->
      @TestController.beforeFilter (callback) ->
        @runs.push 'before'
        callback()
      @TestController.afterFilter (callback) ->
        @runs.push 'after'
        callback()
      @TestController.aroundFilter (callback) ->
        @runs.push 'around_before'
        setImmediate -> callback()
        callback.after (callback) ->
          @runs.push 'around_after'
          callback()
      @controller.process 'indexAction', ->
        assert.deepEqual @runs, ['before', 'around_before', 'index', 'after', 'around_after']
        done()

    describe 'when method filters are given', ->
      beforeEach ->
        @TestController::showAction = (callback) ->
          @runs.push 'show'
          callback()

      it 'does not run callbacks if method is in `except` option', (done) ->
        @TestController.beforeFilter except: 'index', (callback) ->
          @runs.push 'before'
          callback()
        @controller.process 'indexAction', ->
          assert.deepEqual @runs, ['index']
          @runs = []
          @action = 'show'
          @process 'showAction', ->
            assert.deepEqual @runs, ['before', 'show']
            done()

      it 'runs only for methods in `only` option', (done) ->
        @TestController.beforeFilter only: 'index', (callback) ->
          @runs.push 'before'
          callback()
        @controller.process 'indexAction', ->
          assert.deepEqual @runs, ['before', 'index']
          @runs = []
          @action = 'show'
          @process 'showAction', ->
            assert.deepEqual @runs, ['show']
            done()

    describe 'in case of inheritance', ->
      beforeEach ->
        TestController.beforeFilter
        class Child

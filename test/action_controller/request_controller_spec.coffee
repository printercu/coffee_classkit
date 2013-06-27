assert    = require 'assert'
classkit  = require '../../lib/coffee_classkit'

RequestController  = require '../../lib/action_controller/request_controller'

describe 'RequestController', ->
  describe '.dispatch', ->
    beforeEach ->
      class @TestController extends RequestController
        @extendsWithProto()

        constructor: ->
          super
          @runs = []

        indexAction: (callback) ->
          @runs.push 'index'
          setImmediate -> callback?()

    it 'sets req, res, action & next properties', (done) ->
      @TestController::indexAction = (callback) ->
        assert.equal @action, 'index'
        assert.equal @req,    'req'
        assert.equal @res,    'res'
        assert.equal @next,   next
        @runs.push 'index'
        setImmediate callback
      controller = @TestController.dispatch 'index', 'req', 'res', next = ->
        done assert.deepEqual controller.runs, ['index']

    it 'returns created controller instance', ->
      assert @TestController.dispatch('index')?.constructor is @TestController

    it 'runs action method', (done) ->
      controller = @TestController.dispatch 'index', {}, {}, (err) ->
        assert.equal err, null
        assert.deepEqual controller.runs, ['index']
        done()

    context 'if controller does not have requested action', ->
      it 'passes error to callback', (done) ->
        @TestController.dispatch 'missing', {}, {}, (err) ->
          assert err
          done()

      it 'returns `false`', ->
        assert.equal @TestController.dispatch('missing'), false

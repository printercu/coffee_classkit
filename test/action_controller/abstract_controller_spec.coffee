assert    = require 'assert'
classkit  = require '../../lib/coffee_classkit'

AbstractController  = require '../../lib/action_controller/abstract_controller'

describe 'AbstractController', ->
  describe '#process', ->
    beforeEach ->
      class @TestController extends AbstractController
        @extendsWithProto()

        indexAction: (callback) ->
          @runs.push 'index'
          callback?()

      @controller = new @TestController
      @controller.runs = []

    it 'returns instance', ->
      assert.equal @controller.process('indexAction'), @controller

    it 'runs action method', (done) ->
      @controller.process 'indexAction', (err) =>
        assert.equal err, null
        assert.deepEqual @controller.runs, ['index']
        done()

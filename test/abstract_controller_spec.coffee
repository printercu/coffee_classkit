assert    = require 'assert'
classkit  = require '../lib/coffee_classkit'

AbstractController  = require '../lib/abstract_controller'

describe 'AbstractController', ->
  describe 'class', ->
    it 'should create instance', ->
      assert new AbstractController

    it 'should dispatch action', (cb) ->
      AbstractController.dispatch {}, {}, (-> cb()), 'index'

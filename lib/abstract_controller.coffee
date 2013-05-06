_         = require 'underscore'
flow      = require 'flow-coffee'
classkit  = require './coffee_classkit'

# TODO: split it into few more concerns
module.exports =
class AbstractController extends classkit.Module
  @extendsWithProto()
  @include require "./abstract_controller/#{mixin}" for mixin in [
    'base'
    'callbacks'
    'connect'
  ]

  @abstract: true

  constructor: (@req, @res, @next, @action) ->

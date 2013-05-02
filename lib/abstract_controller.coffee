_         = require 'underscore'
flow      = require 'flow-coffee'
classkit  = require './coffee_classkit'
callbacks = require './callbacks'

module.exports = class AbstractController
  classkit.include @, require('./abstract_controller/callbacks')

  @abstract: true

  @actionMethods: (reload) ->
    if @hasOwnProperty('_actionMethods') and @_actionMethods? && !reload
      return @_actionMethods
    klass = @
    @_actionMethods = [].concat.apply([],
      while klass && !(klass.hasOwnProperty('abstract') && klass.abstract)
        methods = Object.keys klass.prototype
        klass = klass.__super__?.constructor
        methods
    ).filter (m) -> /^[^_].*Action$/.test m

  @dispatch: (req, res, next, action) ->
    method = action + 'Action'
    return next 403 unless method in @actionMethods() #forbidden
    controller = new @ req, res, next, action
    callbacks.run @, controller, 'before_process', ->
        controller[method]()
      , next

  constructor: (@req, @res, @next, @action) ->

  prepareData: (data, callback) ->
    callback data

  handleErrors: (fn) -> (err) =>
    return @next err if err
    fn.apply @, arguments

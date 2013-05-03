_         = require 'underscore'
flow      = require 'flow-coffee'
classkit  = require './coffee_classkit'

module.exports = class AbstractController
  classkit.include @, require('./abstract_controller/callbacks')

  @abstract: true

  Object.defineProperty @, 'actionMethods', get: ->
    @hasOwnProperty('_actionMethods') && @_actionMethods ||
      @reloadActionMethods()

  @reloadActionMethods: ->
    klass = @
    @_actionMethods = [].concat.apply([],
      while klass && !(klass.hasOwnProperty('abstract') && klass.abstract)
        methods = Object.keys klass.prototype
        klass = klass.__super__?.constructor
        methods
    ).filter (m) -> /^[^_].*Action$/.test m


  @dispatch: (req, res, next, action) ->
    method = action + 'Action'
    unless method in @actionMethods
      return next if req?.app?.set('env') is 'development'
          new Error "Can not find action `#{action}` in `#{@name}`"
        else
          404 # not found
    instance = new @ req, res, next, action
    instance.process method

  constructor: (@req, @res, @next, @action) ->

  process: (method) ->
    @runCallbacks 'before_process',
      (err, cb) -> do @[method]
      @next

  prepareData: (data, callback) ->
    callback data

  handleErrors: (fn) -> (err) =>
    return @next err if err
    fn.apply @, arguments

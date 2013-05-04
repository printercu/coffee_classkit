_         = require 'underscore'
flow      = require 'flow-coffee'
classkit  = require './coffee_classkit'

# TODO: split it into few more concerns
module.exports =
class AbstractController extends classkit.Module
  @extendsWithProto()
  @include require './abstract_controller/callbacks'

  @abstract: true

  Object.defineProperty @, 'actionMethods', get: ->
    @hasOwnProperty('_actionMethods') && @_actionMethods ||
      @reloadActionMethods()

  ###
  # As of there are all methods are public in js, here is convention about
  # action methods in controllers. Methods that don't start with
  # `_` (underscore) and ends with `Action` are permited action methods.
  #
  # This will invoke _indexAction_ method in controller's instance:
  #
  #   ExampleController.dispatch req, res, next, 'index'
  ###
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

  ###
  # Use it to define error handler for controller. Wrap any callback to handle
  # only successful results.
  #
  #   db.get id, @handleErrors (err, data) ->
  #     # here _err_ is always null
  ###
  handleErrors: (fn) -> (err) =>
    return @next err if err
    fn.apply @, arguments

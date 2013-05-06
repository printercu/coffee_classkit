classkit  = require '../coffee_classkit'

module.exports =
class Base extends classkit.Module
  @extendsWithProto().concern()

  @includedBlock = ->
    Object.defineProperty @, 'actionMethods', get: ->
      @hasOwnProperty('_actionMethods') && @_actionMethods ||
        @reloadActionMethods()

  class @ClassMethods
    ###
    # As of there are all methods are public in js, here is convention about
    # action methods in controllers. Methods that don't start with
    # `_` (underscore) and ends with `Action` are permited action methods.
    #
    # This will invoke _indexAction_ method in controller's instance:
    #
    #   ExampleController.dispatch req, res, next, 'index'
    ###
    reloadActionMethods: ->
      klass = @
      @_actionMethods = [].concat.apply([],
        while klass && !(klass.hasOwnProperty('abstract') && klass.abstract)
          methods = Object.keys klass.prototype
          klass = klass.__super__?.constructor
          methods
      ).filter (m) -> /^[^_].*Action$/.test m


    dispatch: (req, res, next, action) ->
      method = action + 'Action'
      unless method in @actionMethods
        err = if req?.app?.set('env') is 'development'
          new Error "Can not find action `#{action}` in `#{@name}`"
        else
          404 # not found
        return next err
      instance = new @ req, res, next, action
      instance.process method, next


  # instance methods
  process: (method, callback) ->
    @[method] callback

  ###
  # Use it to define error handler for controller. Wrap any callback to handle
  # only successful results.
  #
  #   db.get id, @handleErrors (err, data) ->
  #     # here _err_ is always null
  ###
  handleErrors: (fn) ->
    controller = @
    (err) ->
      return controller.next err if err
      fn.apply @, arguments

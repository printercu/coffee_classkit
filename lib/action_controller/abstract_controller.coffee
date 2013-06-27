classkit  = require '../coffee_classkit'

module.exports =
class AbstractController extends classkit.Module
  @extendsWithProto()

  ###
  # As of property lookup is much faster then search in array _actionMethods_
  # property is no longer in use. It's left for debug purposes.
  ###
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
    ).filter (m) -> /^.*Action$/.test m

  # instance methods
  process: (method, callback) ->
    @[method] callback
    @

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

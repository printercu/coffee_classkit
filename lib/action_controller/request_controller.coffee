classkit  = require '../coffee_classkit'

AbstractController = require './abstract_controller'

module.exports =
class RequestController extends AbstractController
  @extendsWithProto()

  ###
  # As of there are all methods are public in js, here is convention about
  # action methods in controllers. Methods that  ends with `Action`
  # are permited action methods.
  #
  # This will invoke _indexAction_ method in controller's instance:
  #
  #   ExampleController.dispatch req, res, next, 'index'
  ###  
  @dispatch: (action, req, res, next) ->
    method = action + 'Action'
    # unless method in @actionMethods
    unless method of @::
      err = if req?.app?.set('env') is 'development'
        new Error "Can not find action `#{action}` in `#{@name}`"
      else
        404 # not found
      next? err
      return false
    instance = new @ action, req, res, next
    instance.process method, next

  constructor: (@action, @req, @res, @next) ->

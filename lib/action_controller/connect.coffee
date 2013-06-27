classkit  = require '../coffee_classkit'

module.exports =
class Connect extends classkit.Module
  @extendsWithProto().concern()

  ###
  # Use connect-compatible middleware in filters.
  #
  #   @beforeFilter only: 'index', @connectMiddleware require('connect').json()
  #
  ###
  class @ClassMethods
    connectMiddleware: (middleware) -> (err, callback) ->
      middleware @req, @res, (err) ->
        # force one argument
        callback err

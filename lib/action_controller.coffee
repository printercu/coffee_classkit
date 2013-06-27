classkit  = require './coffee_classkit'

RequestController = require './action_controller/request_controller'

module.exports =
class ActionController extends RequestController
  @extendsWithProto()

  @includeAll module, prefix: './action_controller',
    'connect'
    'callbacks'

  @abstract: true

_         = require 'underscore'
classkit  = require '../coffee_classkit'
callbacks = require '../callbacks'

module.exports = class Callbacks
  classkit.concern @

  @included ->
    callbacks.define @, 'before_process'
    callbacks.define @, 'after_process'

  @ClassMethods =
    beforeFilter: (args..., filter) ->
      options = args[0] || {}
      callbacks.add @, 'before_process', normalize_options(options), filter

    skipBeforeFilter: (args..., filter) ->
      options = args[0] || {}
      callbacks.skip @, 'before_process', normalize_options(options), filter

    afterFilter: (args..., filter) ->
      options = args[0] || {}
      callbacks.add @, 'after_process', normalize_options(options), filter

    skipAfterFilter: (args..., filter) ->
      options = args[0] || {}
      callbacks.skip @, 'after_process', normalize_options(options), filter

  normalize_options = (options) ->
    return options if typeof options is 'function'
    if:     normalize_option options.only
    unless: normalize_option options.except
    when:   options.when

  normalize_option = (options) ->
    (
      "@action is '#{action}'" for action in _.compact _.flatten [options]
    ).join ' or '

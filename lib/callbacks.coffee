cs        = require 'coffee-script'
_         = require 'underscore'
flow      = require 'flow-coffee'
classkit  = require './coffee_classkit'

module.exports =
class Callbacks extends classkit.Module
  @extendsWithProto().concern()

  class @ClassMethods
    defineCallbacks: (name) ->
      @[key name] = []
      @

    setCallback: (name, args...) ->
      [options, filter] = classkit.findOptions args
      item    = [[filter, normalize_options options]]
      origin  = @[key name]
      @[key name] = if options.prepend
       item.concat origin
      else
        origin.concat item
      @_compileCallbacks name

    # TODO: support for options
    skipCallback: (name, args...) ->
      [options, filter] = classkit.findOptions args
      @[key name] = if filter
        @[key name].filter ([item, options]) -> item != filter
      else
        []
      @_compileCallbacks name

    runCallbacks: (context, name, callback, error) ->
      if (chain = @[key_compiled name])?.length
        (new flow
          context: context
          blocks: chain.concat [callback]
          error: error
        ) null
      else
        callback.call context
      @

    _compileCallbacks: (name) ->
      @[key_compiled name] = _.flatten(
        for [filter, options] in @[key name]
          if options.if.length or options.unless.length
            [compile_options(options), filter]
          else
            [filter]
      )
      @

  # instance methods
  runCallbacks: (name, callback, error) ->
    @constructor.runCallbacks @, name, callback, error

  # private helpers
  key = (name) -> "_#{name}_callbacks"
  key_compiled = (name) -> "_#{name}_callbacks_compiled"

  normalize_options = (options) ->
    return options if typeof options is 'function'
    if:     _.compact _.flatten [options.if]
    unless: _.compact _.flatten [options.unless]

  compile_options = (options) ->
    return options if typeof options is 'function'
    return options.when if options.when
    clauses = options.if
    clauses.push "!(#{options.unless.join ' and '})" if options.unless.length
    # OPTIMIZE: replace args... with err
    eval cs.compile """
      (args..., cb) ->
        cb.skip() unless #{clauses.join ' and '}
        cb.next args...
    """, bare: true

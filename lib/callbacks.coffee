cs        = require 'coffee-script'
_         = require 'underscore'
flow      = require 'flow-coffee'
classkit  = require './coffee_classkit'

module.exports =
class Callbacks extends classkit.Module
  @extendsWithProto().concern()

  class @ClassMethods
    defineCallbacks: (name) ->
      for type in ['before', 'after']
        @[key name, type] = []
        @_compileCallbacks name, type
      @

    ###
    # TODO:
    # On setting previously set callback new one is just prepending with
    # new options. May be we should merge that callbacks into first one.
    # But we woun't be able to declare duplicates...
    #
    # Find out how to extract skipped options. Maybe concat arrays with _or_.
    ###
    setCallback: (name, type, args...) ->
      [options, filter] = classkit.findOptions args
      item    = [[filter, normalize_options options]]
      origin  = @[key name, type]
      @[key name, type] = if options.prepend
        item.concat origin
      else
        origin.concat item
      @_compileCallbacks name, type

    skipCallback: (name, type, args...) ->
      [skip_options, filter] = classkit.findOptions args
      @[key name, type] = if filter
        _.compact @[key name, type].map ([item, options]) ->
          return arguments[0] if item != filter
          if new_options = merge_skipped_options options, skip_options
            [item, new_options]
      else
        []
      @_compileCallbacks name, type

    runCallbacks: ->
      (@prepareCallbacks arguments...) null

    prepareCallbacks: (context, name, callback, options) ->
      blocks = @[key_compiled name, 'before']
        .concat [callback], @[key_compiled name, 'after']
      flow_opts =
        context:  context
        blocks:   blocks
      if options
        if typeof options is 'object'
          flow_opts.error = options.error if options.error
          flow_opts.final = options.final if options.final
        else
          flow_opts.error = options
          flow_opts.final = -> options.apply(context, [null].concat(Array::slice.call(arguments)))
      new flow flow_opts

    _compileCallbacks: (name, type) ->
      @[key_compiled name, type] = _.flatten(
        for [filter, options] in @[key name, type]
          if options.if.length or options.unless.length
            [compile_options(options), filter]
          else
            [filter]
      )
      @

  # instance methods
  runCallbacks: ->
    (@prepareCallbacks arguments...) null

  prepareCallbacks: (name, callback, options) ->
    @constructor.prepareCallbacks @, name, callback, options

  # private helpers
  key = (name, type) -> "_#{type}_#{name}_callbacks"
  key_compiled = (name, type) -> "_#{type}_#{name}_callbacks_compiled"

  normalize_options = (options) ->
    return options if typeof options is 'function'
    if:     _.compact _.flatten [options.if]
    unless: _.compact _.flatten [options.unless]

  merge_skipped_options = (options, skipOptions) ->
    skip_opts = normalize_options skipOptions
    return false unless skip_opts.if.length or skip_opts.unless.length
    if:     options.if.concat     skip_opts.unless
    unless: options.unless.concat skip_opts.if

  compile_options = (options) ->
    return options if typeof options is 'function'
    return options.when if options.when
    clauses = options.if.slice 0
    clauses.push "!(#{options.unless.join ' and '})" if options.unless.length
    # OPTIMIZE: replace args... with err ?
    eval cs.compile """
      (args..., cb) ->
        cb.skip() unless #{clauses.join ' and '}
        cb.next args...
    """, bare: true

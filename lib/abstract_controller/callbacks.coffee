cs        = require 'coffee-script'
_         = require 'underscore'
lingo     = require 'lingo'
classkit  = require '../coffee_classkit'

module.exports =
class Callbacks extends classkit.Module
  @extendsWithProto().concern()

  @include require '../callbacks'

  @includedBlock = ->
    @defineCallbacks 'process'
    @aliasMethodChain 'process', 'callbacks'

  class @ClassMethods
    for type in ['before', 'after']
      @::["#{type}Filter"] = eval cs.compile """
        ->
          [options, filter] = normalize_args arguments
          @setCallback 'process', '#{type}', options, filter
      """, bare: true

      @::[lingo.camelcase "skip #{type} filter"] = eval cs.compile """
        ->
          [options, filter] = normalize_args arguments
          @skipCallback 'process', '#{type}', options, filter
      """, bare: true
    # use it to show that this callback is using _flow.after_
    classkit.aliasMethod @, 'aroundFilter', 'beforeFilter'
    classkit.aliasMethod @, 'skipAroundFilter', 'skipBeforeFilter'

  # instance methods
  processWithCallbacks: (method) ->
    @runCallbacks 'process',
      (err, flow) -> @processWithoutCallbacks method, flow
      error:  @next
      final:  @req.next

  # private helpers
  normalize_args = (args) ->
    [options, filter] = classkit.findOptions args
    [
      if:     normalize_option options.only
      unless: normalize_option options.except
      when:   options.when
      filter
    ]

  normalize_option = (options) ->
    ("@action is '#{action}'" for action in _.compact _.flatten [options]
    ).join ' or '

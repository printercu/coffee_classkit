cs        = require 'coffee-script'
_         = require 'underscore'
lingo     = require 'lingo'
classkit  = require '../coffee_classkit'

module.exports = class Callbacks
  classkit.concern @

  classkit.include @, require '../callbacks'

  @includedBlock = ->
    @defineCallbacks 'before_process'
    @defineCallbacks 'after_process'

  class @ClassMethods
    for type in ['before', 'after']
      @::["#{type}Filter"] = eval cs.compile """
        ->
          [options, filter] = normalize_args arguments
          @setCallback "#{type}_process", options, filter
      """, bare: true

      @::[lingo.camelcase "#skip #{type} filter"] = eval cs.compile """
        ->
          [options, filter] = normalize_args arguments
          @skipCallback "#{type}_process", options, filter
      """, bare: true

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

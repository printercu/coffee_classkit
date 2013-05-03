cs        = require 'coffee-script'
_         = require 'underscore'
lingo     = require 'lingo'
classkit  = require '../coffee_classkit'
callbacks = require '../callbacks'

module.exports = class Callbacks
  classkit.concern @

  @included ->
    callbacks.define @, 'before_process'
    callbacks.define @, 'after_process'

  @ClassMethods = {}
  ['before', 'after'].forEach (type) =>
    @ClassMethods["#{type}Filter"] = eval cs.compile """
      ->
        [options, filter] = normalize_args arguments
        callbacks.add @, "#{type}_process", options, filter
    """, bare: true

    @ClassMethods[lingo.camelcase "#skip_{type}_filter"] = eval cs.compile """
      ->
        [options, filter] = normalize_args arguments
        callbacks.skip @, "#{type}_process", options, filter
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

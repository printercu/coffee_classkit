classkit = class Classkit
  # # Inheritance
  # Under development.
  # No docs yet. See ruby analogs.

  # This fields should be skipped when _include_ & _extend_ are performed not
  # to override js & coffee inheritance model.
  #
  # We also need to skip _extendsWithProto_ in extend. It allows to call it
  # from class that not extending _classkit.Module_.
  @SKIP_IN_EXTEND:   ['__super__', 'extendsWithProto']
  @SKIP_IN_INCLUDE:  ['constructor']

  # Makes class methods inherited by prototype chain.
  # Sadly it cannot be performed automaticaly, so you need call this method
  # on each class where you need this functionality.
  #
  #   class Parent
  #     @attr: 1
  #
  #   class Child extends Parent
  #     classkit.extendsWithProto @
  #
  #   Child.hasOwnProperty('attr')
  #   # => false
  #   Child.attr
  #   # => 1
  @extendsWithProto: (klass)->
    for name of klass
      if klass.hasOwnProperty(name) && name not in @SKIP_IN_EXTEND
        delete klass[name]
    if klass.__super__
      klass.__proto__ = klass.__super__.constructor
      klass.__proto__.inherited? klass
    @

  @extend: (object, mixin) ->
    if mixin.extendObject
      mixin.extendObject object
    else
      @extendObject mixin, object
    mixin.extended? klass
    @

  @extendObject: (mixin, object) ->
    @extendObject mixin.__super__.constructor, object if mixin.__super__
    for name in Object.getOwnPropertyNames mixin::
      continue if name in @SKIP_IN_EXTEND
      Object.defineProperty object, name,
        Object.getOwnPropertyDescriptor mixin::, name
    @

  @include: (klass, mixin) ->
    if mixin.appendFeatures
      mixin.appendFeatures klass
    else
      @appendFeatures mixin, klass
    mixin.included? klass
    @

  @appendFeatures: (mixin, klass) ->
    @appendFeatures mixin.__super__.constructor, klass if mixin.__super__
    for name in Object.getOwnPropertyNames mixin::
      continue if name in @SKIP_IN_INCLUDE
      Object.defineProperty klass::, name,
        Object.getOwnPropertyDescriptor mixin::, name
    @

  # ActiveSupport::Concern's analog.
  #
  #   class Mixin
  #     classkit.concern @
  #
  #     @includedBlock = ->
  #       # here is context of base class
  #       @defineCallbacks 'action'
  #
  #     class @ClassMethods
  #       someClassMethod: ->
  #         # ...
  #
  #     # instance methods
  #     someInstanceMethod: ->
  #       # ...
  #
  #   class Base
  #     classkit.extendsWithProto @
  #     classkit.include @, Mixin
  #     # callbacks are already defined
  #
  #     # use class methods
  #     @someClassMthod()
  #
  #   # use instance methods
  #   obj = new Base
  #   obj.someInstanceMethod()
  @concern: (klass) ->
    @instanceVariable klass, '_dependencies', []
    @instanceVariable klass, 'includedBlock'

    klass.appendFeatures = (base) ->
      if base._dependencies
        base._dependencies.push @
        return false
      return false if classkit.isSubclass base, @
      classkit.include base, dep for dep in @_dependencies
      classkit.appendFeatures @, base
      classkit.extend base, @ClassMethods if @hasOwnProperty 'ClassMethods'
      @includedBlock?.call base, classkit
    @

  @isSubclass: (klass, other) ->
    while klass.__proto__
      return true if klass.__proto__ is other
      klass = klass.__proto__
    false

  # # Variables
  @instanceVariable: (obj, name, val) ->
    private_name = "_#{name}"
    Object.defineProperty obj, name,
      get: -> @[private_name] if @hasOwnProperty private_name
      set: (val) -> @[private_name] = val
    obj[name] = val
    @

  @classVariable: (obj, name, data) ->
    Object.defineProperty obj, name,
      get: -> data
      set: (val) -> data = val
    @

  @classAttribute: (obj, name, data) ->
    obj[name] = data
    private_name = "_#{name}"
    Object.defineProperty obj::, name,
      get: -> if @hasOwnProperty(private_name) then @[private_name] else @constructor[name]
      set: (value) -> @[private_name] = value

  # # Aliasing
  @aliasMethod: (klass, to, from) ->
    unless klass::[from]?
      throw new Error "No such method #{klass.name}##{from}"
    klass::[to] = klass::[from]
    @

  @aliasMethodChain: (klass, method, feature) ->
    feature = feature.charAt(0).toUpperCase() + feature.substr 1
    method_with     = "#{method}With#{feature}"
    method_without  = "#{method}Without#{feature}"
    @aliasMethod klass, method_without, method
    @aliasMethod klass, method, method_with

  # # Misc
  @requireAll: (module, args...) ->
    [options, mixins] = @findOptions args
    prefix = "#{options.prefix}/" if options.prefix?
    module.require "#{prefix}#{mixin}" for mixin in mixins

  @includeAll: (klass, args...) ->
    @include klass, module for module in @requireAll args...

  @extendAll: ->
    @extend klass, module for module in @requireAll args...

  @CHAINABLE_CLASSKIT_METHODS: [
    'extendsWithProto'
    'extend'
    'extendObject'
    'include'
    'appendFeatures'
    'concern'
    'instanceVariable'
    'classVariable'
    'classAttribute'
    'aliasMethod'
    'aliasMethodChain'
    'includeAll'
    'extendAll'
  ]

  @NOT_CHAINABLE_CLASSKIT_METHODS: [
    'isSubclass'
  ]

  # Injects all classkit methods as class methods into target.
  @inject: (klass) ->
    @CHAINABLE_CLASSKIT_METHODS.forEach (method) ->
      klass[method] = ->
        classkit[method] @, arguments...
        @
    @NOT_CHAINABLE_CLASSKIT_METHODS.forEach (method) ->
      klass[method] = -> classkit[method] @, arguments...

  # Simple class with injected methods. Use it as a top of your class hierarchy.
  # Do not forget to call _extendsWithProto_ in inherited classes.
  #
  # Common ussage:
  #
  #   class Parent extends classkit.Module
  #     @extendsWithProto()
  #
  #   class Mixin extends classkit.Module
  #     @extendsWithProto().concern()
  #
  #   class Child extends Parent
  #     @extendsWithProto()
  #     @include Mixin
  @Module: class Module
  @inject @Module

  # TODO: move helpers out
  # # Helpers

  # Returns _[options, [other_args]]_. Options are taken from first or last
  # element if it's object. Last element is prefered. If they are not objects
  # _{}_ is returned in place of _options_.
  #
  #   classkit.findOptions param, opt: 'val'
  #   # => [{opt: 'val'}, [param]]
  #   classkit.findOptiona opt: 'val', ->
  #     # ...
  #   # => [{opt: 'val'}, [function]]
  #
  # Supports one argument as array or arguments object
  @findOptions: (args) ->
    return [{}, []] unless args?.length
    last_id = args.length - 1
    if typeof (last = args[last_id]) is 'object'
      [last, Array::slice.call(args, 0, last_id)]
    else if typeof args[0] is 'object'
      [args[0], Array::slice.call(args, 1)]
    else
      [{}, Array::slice.call args]

# export
if module?.exports
  module.exports = classkit
else if define?.amd
  define -> classkit
else
  @classkit = classkit

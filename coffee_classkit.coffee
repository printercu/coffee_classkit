class Classkit
  # # Inheritance
  # Under development.
  # No docs yet. See ruby analogs.

  # This fields should be skipped when _include_ & _extend_ are performed not
  # to override js & coffee inheritance model.
  #
  # We also need to skip _extendsWithProto_ in extend. It allows to call it
  # from class that not extending _Classkit.Module_.
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
  #     Classkit.extendsWithProto @
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

  @_copy_props: (object, mixin) ->
    for name in Object.getOwnPropertyNames mixin::
      continue if name in @SKIP_IN_INCLUDE
      Object.defineProperty object, name,
        Object.getOwnPropertyDescriptor mixin::, name

  @extend: (object, mixin) ->
    if mixin.extendObject
      mixin.extendObject object
    else
      @extendObject mixin, object
    mixin.extended? klass
    @

  @extendObject: (mixin, object) ->
    @extendObject mixin.__super__.constructor, object if mixin.__super__
    @_copy_props object, mixin
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
    @_copy_props klass::, mixin
    @

  # ActiveSupport::Concern's analog.
  #
  #   class Mixin
  #     Classkit.concern @
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
  #     Classkit.extendsWithProto @
  #     Classkit.include @, Mixin
  #     # callbacks are already defined
  #
  #     # use class methods
  #     @someClassMthod()
  #
  #   # use instance methods
  #   obj = new Base
  #   obj.someInstanceMethod()
  @concern: (klass) ->
    @instanceVariable klass, '_dependencies', 'includedBlock'
    klass._dependencies = []

    klass.appendFeatures = (base) ->
      if base._dependencies
        base._dependencies.push @
        return false
      return false if Classkit.isSubclass base, @
      Classkit.include base, dep for dep in @_dependencies
      Classkit.appendFeatures @, base
      Classkit.extend base, @ClassMethods if @hasOwnProperty 'ClassMethods'
      @includedBlock?.call base, Classkit
    @

  @isSubclass: (klass, other) ->
    while klass.__proto__
      return true if klass.__proto__ is other
      klass = klass.__proto__
    false

  # # Variables
  @instanceVariable: (obj, attrs...) ->
    for name in attrs
      do (name) ->
        private_name = "_#{name}"
        Object.defineProperty obj, name,
          get: -> @[private_name] if @hasOwnProperty private_name
          set: (val) -> @[private_name] = val
    @

  @classVariable: (obj, attrs...) ->
    for name in attrs
      do (name, data = undefined) ->
        Object.defineProperty obj, name,
          get: -> data
          set: (val) -> data = val
    @

  @classAttribute: (obj, attrs...) ->
    for name in attrs
      do (name) ->
        private_name = "_#{name}"
        Object.defineProperty obj::, name,
          get: -> if @hasOwnProperty(private_name) then @[private_name] else @constructor[name]
          set: (value) -> @[private_name] = value
    @

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
  @requireAll: (module, mixins...) ->
    options = if typeof mixins[0] is 'object'
      mixins.shift()
    else
      {}
    prefix = "#{options.prefix}/" if options.prefix?
    module.require "#{prefix ? ''}#{mixin}" for mixin in mixins

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

  # Injects all Classkit methods as class methods into target.
  @inject: (klass) ->
    @CHAINABLE_CLASSKIT_METHODS.forEach (method) ->
      klass[method] = ->
        Classkit[method] @, arguments...
        @
    @NOT_CHAINABLE_CLASSKIT_METHODS.forEach (method) ->
      klass[method] = -> Classkit[method] @, arguments...

  # Simple class with injected methods. Use it as a top of your class hierarchy.
  # Do not forget to call _extendsWithProto_ in inherited classes.
  #
  # Common ussage:
  #
  #   class Parent extends Classkit.Module
  #     @extendsWithProto()
  #
  #   class Mixin extends Classkit.Module
  #     @extendsWithProto().concern()
  #
  #   class Child extends Parent
  #     @extendsWithProto()
  #     @include Mixin
  class @Module
  @inject @Module

  # Method to use in pure js.
  # It applies CoffeeScript's inheritance first and Classkit's then.
  #
  #   function Parent() { /* ... */ }
  #   var Child;
  #   Classkit.inherit(Parent, Child = function Child(){ /* ... */ });
  class extends Object
  @inherit: (parent, child) ->
    `__extends(child, parent)`
    @extendsWithProto child
    child

# export
if module?.exports
  module.exports = Classkit
else if define?.amd
  define -> Classkit
else
  @Classkit = Classkit

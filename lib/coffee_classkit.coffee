classkit =
  ###
  # Here are defined fields to skip while performing _include_ & _extend_ not
  # to override js & coffee-script inferitance model.
  #
  # We also need to skip _extendsWithProto_ in extend. It allows to call it
  # from class that not extending _classkit.ClasskitModule_.
  ###
  SKIP_IN_EXTEND:  SKIP_IN_EXTEND  = ['__super__', 'extendsWithProto']
  SKIP_IN_INCLUDE: SKIP_IN_INCLUDE = ['constructor']

  ###
  # Inheritance
  # Under development.
  # No docs yet. See ruby analogs.
  ###

  ###
  # Makes class methods inherited by prototype chain.
  # Sadly it cannot be performed automaticaly, so you need call this method
  # on each class where you need this functionality.
  #
  #   class Parent
  #     @param: 1
  #
  #   class Child extends Parent
  #     classkit.extendsWithProto @
  #
  #   Child.hasOwnProperty('param')
  #   # => false
  #   Child.param
  #   # => 1
  ###
  extendsWithProto: (klass)->
    for name of klass
      if klass.hasOwnProperty(name) && name not in SKIP_IN_EXTEND
        delete klass[name]
    klass.__proto__ = klass.__super__.constructor if klass.__super__
    @

  extend: (object, mixin) ->
    if mixin.extendObject
      mixin.extendObject object
    else
      @extendObject mixin, object
    mixin.extended? klass
    @

  extendObject: (mixin, object) ->
    for name, method of mixin::
      object[name] = method if name not in SKIP_IN_EXTEND
    @

  include: (klass, mixin) ->
    if mixin.appendFeatures
      mixin.appendFeatures klass
    else
      @appendFeatures mixin, klass
    mixin.included? klass
    @

  appendFeatures: (mixin, klass) ->
    for name, method of mixin::
      klass::[name] = method if name not in SKIP_IN_INCLUDE
    @

  concern: (klass) ->
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

  isSubclass: (klass, other) ->
    while klass.__proto__
      return true if klass.__proto__ is other
      klass = klass.__proto__
    false

  # variables
  instanceVariable: (obj, name, val) ->
    private_name = "_#{name}"
    Object.defineProperty obj, name,
      get: -> @[private_name] if @hasOwnProperty private_name
      set: (val) -> @[private_name] = val
    obj[name] = val
    @

  classVariable: (obj, name, data) ->
    Object.defineProperty obj, name,
      get: -> data
      set: (val) -> data = val
    @

  # aliasing

  ###
  # Unlike Ruby's method this one accepts original method name
  # as first parameter.
  ###
  aliasMethod: (klass, from, to) ->
    klass::[to] = klass::[from]
    @

  aliasMethodChain: (klass, method, feature) ->
    feature = feature.charAt(0).toUpperCase() + feature.substr 1
    method_with     = "#{method}With#{feature}"
    method_without  = "#{method}Without#{feature}"
    @aliasMethod klass, method, method_without
    @aliasMethod klass, method_with, method

  ###
  # Provides all the classkit's methods as class methods. Use it as a top
  # of your classes hierarchy. Do not forget to call _extendsWithProto_ in
  # inherited classes.
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
  ###
  Module: class Module
    CHAINABLE_CLASSKIT_METHODS = [
      'extendsWithProto'
      'extend'
      'extendObject'
      'include'
      'appendFeatures'
      'concern'
      'classVariable'
      'instanceVariable'
      'aliasMethod'
      'aliasMethodChain'
    ]
    NOT_CHAINABLE_CLASSKIT_METHODS = [
      'isSubclass'
    ]
    CHAINABLE_CLASSKIT_METHODS.forEach (method) =>
      @[method] = ->
        classkit[method] @, arguments...
        @
    NOT_CHAINABLE_CLASSKIT_METHODS.forEach (method) =>
      @[method] = -> classkit[method] @, arguments...

  # TODO: move helpers out
  # helpers

  ###
  # Returns _[options, other_args...]_. Options are taken from first or last
  # element if it's object. Last element is prefered. If they are not objects
  # _{}_ is returned in place of _options_.
  #
  #   classkit.findOptions param, opt: 'val'
  #   # => [{opt: 'val'}, param]
  #   classkit.findOptiona opt: 'val', ->
  #     # ...
  #   # => [{opt: 'val'}, function]
  #
  # Supports one argument as array (or arguments object) or multiple
  ###
  findOptions: (args) ->
    args = arguments if arguments.length > 1
    return [{}] unless args?.length
    if typeof (last = args[args.length - 1]) is 'object'
      [last, Array::slice.call(args, 0, args.length - 1)...]
    else if typeof args[0] is 'object'
      args
    else
      [{}, args...]

# export
if module?.exports
  module.exports = classkit
else if define?.amd
  define -> classkit
else
  @classkit = classkit

SKIP_IN_INCLUDE = ['ClassMethods']

classkit =
  # inheritance
  extendsWithProto: (klass)->
    for key of klass
      delete klass[key] if klass.hasOwnProperty(key) && key != '__super__'
    klass.__proto__ = klass.__super__.constructor if klass.__super__
    @

  extend: (object, mixin) ->
    if mixin.extendObject
      mixin.extendObject object, @
    else
      @extendObject mixin, object
    mixin.extended klass, @ if mixin.extended
    @

  extendObject: (mixin, object) ->
    object[name] = method for name, method of mixin
    @

  include: (klass, mixin) ->
    if mixin.appendFeatures
      mixin.appendFeatures klass, @
    else
      @appendFeatures mixin, klass
    mixin.included klass, @ if mixin.included
    @

  appendFeatures: (mixin, klass) ->
    klass::[name] = method for name, method of mixin when name not in SKIP_IN_INCLUDE
    @extend klass, mixin.ClassMethods if mixin.ClassMethods
    @

  concern: (klass) ->
    @instanceVariable klass, '_dependencies', []
    @instanceVariable klass, '_included_block'

    klass.appendFeatures = (base) ->
      if base._dependencies
        base._dependencies.push @
        return false
      return false if classkit.isSubclass base, @
      classkit.include base, dep for dep in @_dependencies
      classkit.appendFeatures @, base
      classkit.extend base, @ClassMethods if @ClassMethods
      @_included_block?.call base, classkit

    klass.included = (fn) ->
      @_included_block  = fn
      # super?

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

  # helpers
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

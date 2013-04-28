classkit =
  extendsWithProto: (klass)->
    for key of klass
      delete klass[key] if klass.hasOwnProperty(key) && key != '__super__'
    klass.__proto__ = klass.__super__.constructor
    @

  extend: (klass, mixin) ->
    klass[name] = method for name, method of mixin
    @

  include: (klass, mixin) ->
    klass::[name] = method for name, method of mixin
    @

  instanceVariable: (obj, name) ->
    private_name = "_#{name}"
    Object.defineProperty obj, name,
      get: -> @[private_name] if @hasOwnProperty private_name
      set: (val) -> @[private_name] = val

  classVariable: (obj, name) ->
    data = undefined
    Object.defineProperty obj, name,
      get: -> data
      set: (val) -> data = val

if module?.exports
  module.exports = classkit
else if define?.amd
  define -> classkit
else
  @classkit = classkit
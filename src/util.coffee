do ->
  # Clones non-null objects.  Not arrays or other primitives.  Maybe.  It
  # depends on browser version.
  #
  # TODO: Fix super classes.  Maybe this will just work when we upgrade to
  # CoffeeScript v2.
  cloneObject = (obj) ->
    proto = Object.getPrototypeOf(obj)
    clone = Object.create(proto)
    for k, v of obj
      clone[k] = v
    clone

  # Return random integer in interval [0...n].
  randInt = (n) ->
    Math.floor(Math.random() * (n+1))

  # Exports
  export default
    cloneObject: cloneObject
    randInt: randInt

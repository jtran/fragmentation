import _ from './underscore.js'

# Clones non-null objects.  Not arrays or other primitives.  Maybe.  It
# depends on browser version.
export cloneObject = (obj) ->
  proto = Object.getPrototypeOf(obj)
  clone = Object.create(proto)
  for k, v of obj
    clone[k] = v
  clone

# Return random integer in interval [0...n].
export randInt = (n) ->
  Math.floor(Math.random() * (n+1))

export without = (arr, item) ->
  x for x in arr when not _.isEqual(x, item)

export default {
  cloneObject,
  randInt,
  without,
}

import _ from './underscore.js'

# Clones non-null objects.  Not arrays or other primitives.  Maybe.  It
# depends on browser version.
export cloneObject = (obj) ->
  proto = Object.getPrototypeOf(obj)
  clone = Object.create(proto)
  for k, v of obj
    clone[k] = v
  clone

# Return the max of an array or undefined if it's empty.  Unlike splatting
# Math.max(), this works on large arrays.
export max = (arr) ->
  return undefined if arr.length == 0
  x = arr[0]
  x = y for y in arr when y > x
  x

# Return random integer in interval [0...n].
export randInt = (n) ->
  Math.floor(Math.random() * (n+1))

# Returns unique elements in array, preserving order.  Same-value-zero equality
# is used.
export unique = (arr) ->
  [new Set(arr)...]

export without = (arr, item) ->
  x for x in arr when not _.isEqual(x, item)

export default {
  cloneObject,
  max,
  randInt,
  unique,
  without,
}

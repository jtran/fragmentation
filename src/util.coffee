class AutoIncGenerator
  constructor: (@prefix) ->
    @prefix ?= ''
    @curId = 0

  nextId: ->
    id = @curId
    @curId++
    # Wrap around instead of spilling into floating point.
    @curId = 0 if @curId == Number.MAX_SAFE_INTEGER
    id

  nextIdStr: ->
    @prefix + @nextId()

export autoIncGenerator = (prefix) -> new AutoIncGenerator(prefix)

# Clones non-null objects.  Not arrays or other primitives.  Maybe.  It
# depends on browser version.
export cloneObject = (obj) ->
  proto = Object.getPrototypeOf(obj)
  clone = Object.create(proto)
  for k, v of obj
    clone[k] = v
  clone

# Same-value-zero.
export eq = (x, y) ->
  x == y or x != x and y != y

# Return the max of an array or undefined if it's empty.  Unlike splatting
# Math.max(), this works on large arrays.
export max = (arr) ->
  return undefined if arr.length == 0
  x = arr[0]
  x = y for y in arr when y > x
  x

# Return the min of an array or undefined if it's empty.  Unlike splatting
# Math.min(), this works on large arrays.
export min = (arr) ->
  return undefined if arr.length == 0
  x = arr[0]
  x = y for y in arr when y < x
  x

# Return random integer in interval [0...n].
export randInt = (n) ->
  Math.floor(Math.random() * (n+1))

export sortBy = (arr, fn) ->
  objs = arr.map (x) -> { value: x, criterion: fn(x) }
  objs.sort (x, y) ->
    a = x.criterion
    b = y.criterion
    if a < b then -1
    else if a > b then 1
    else 0
  objs.map (obj) -> obj.value

# Returns unique elements in array, preserving order.  Same-value-zero equality
# is used.
export unique = (arr) ->
  [new Set(arr)...]

# TODO: Use structural equality.
export without = (arr, item) ->
  x for x in arr when not eq(x, item)

export default {
  autoIncGenerator,
  cloneObject,
  eq,
  max,
  min,
  randInt,
  sortBy,
  unique,
  without,
}

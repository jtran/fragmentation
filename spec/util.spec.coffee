# this line is checking that there is a default export in util
import util from '../lib/util.js'

import { cloneObject } from '../lib/util.js'

describe 'util', ->

  class Vehicle
    capacity: -> 1

  class Car extends Vehicle
    constructor: ->
      super()
      @color = 'black'

    wheels: -> 4

  it "clones object's own properties", ->
    car = new Car()
    car.color = 'blue'
    v = cloneObject(car)
    expect(v.color).to.equal 'blue'

  it "clones object with same prototype chain", ->
    car = new Car()
    v = cloneObject(car)
    expect(v.color).to.equal 'black'
    expect(v.wheels()).to.equal 4
    expect(v.capacity()).to.equal 1
    expect(Object.getPrototypeOf(v)).to.equal Car.prototype

  it "returns unique numbers in array", ->
    expect(util.unique([0, 1, 1, 2, 3, 4, 3, 4, 0, 3])).to.deep.equal [0, 1, 2, 3, 4]

  it "returns unique objects in array", ->
    a = {}
    b = {}
    c = null
    d = undefined
    expect(util.unique([a, a, b, b, c, c, d, d])).to.deep.equal [a, b, c, d]

  it "returns array without a number element", ->
    arr = [1, 2, 3]
    r = util.without(arr, 3)
    expect(r).to.have.ordered.members [1, 2]

  it "returns array without an object element", ->
    a = { a: 1 }
    b = { b: 2 }
    c = { c: 3 }
    arr = [a, b, c]
    r = util.without(arr, a)
    expect(r).to.have.ordered.members [b, c]

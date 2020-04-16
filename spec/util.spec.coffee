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

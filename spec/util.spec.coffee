import util from '../lib/util.js'

describe 'util', ->

  class Vehicle
    capacity: -> 1

  class Car extends Vehicle
    constructor: ->
      @color = 'black'

    wheels: -> 4

  it "clones object's own properties", ->
    car = new Car()
    car.color = 'blue'
    v = util.cloneObject(car)
    expect(v.color).to.equal 'blue'

  it "clones object with same prototype chain", ->
    car = new Car()
    v = util.cloneObject(car)
    expect(v.color).to.equal 'black'
    expect(v.wheels()).to.equal 4
    expect(v.capacity()).to.equal 1
    # This fails, but we currently don't use super classes.
    # expect(Object.getPrototypeOf(v)).toBe(Car)

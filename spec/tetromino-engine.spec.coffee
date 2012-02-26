engine = require '../views/tetromino-engine'

describe 'tetromino-engine', ->

  it "triggers new block event", ->
    expect(new engine.Block()).toBeTruthy()

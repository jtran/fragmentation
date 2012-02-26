requirejs = require('requirejs')
requirejs.config {
  baseUrl: __dirname + '/../lib'
  nodeRequire: require
}
requirejs.define 'jquery', [], ->
  -> console.error("You tried to use jQuery on the server.")


requirejs ['tetromino-engine'], (engine) ->

  describe 'tetromino-engine', ->

    it "triggers new block event", ->
      expect(new engine.Block()).toBeTruthy()

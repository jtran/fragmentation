requirejs = require('requirejs')
requirejs.config {
  baseUrl: __dirname + '/../lib'
  nodeRequire: require
}
requirejs.define 'jquery', [], ->
  -> console.error("You tried to use jQuery on the server.")


requirejs ['tetromino-engine', 'decouple'], (engine, decouple) ->

  describe 'tetromino-engine Block', ->

    it "constructs new block with given x and y", ->
      blk = new engine.Block({}, {}, 1, 2)
      expect(blk.x).toEqual 1
      expect(blk.y).toEqual 2

    it "triggers new block event", ->
      spyOn(decouple, 'trigger')
      field = {}
      piece = {}
      blk = new engine.Block(field, piece, 1, 2)
      expect(decouple.trigger).toHaveBeenCalledWith(field, 'new Block', blk, piece)

    it "triggers move block event when setting xy", ->
      blk = new engine.Block({}, {}, 1, 2)
      spyOn(decouple, 'trigger')
      blk.setXy([3, 4])
      expect(decouple.trigger).toHaveBeenCalledWith(blk, 'move Block')


  describe 'tetromino-engine PlayingField', ->

    it "triggers new playing field event", ->
      spyOn(decouple, 'trigger')
      game = {}
      field = new engine.PlayingField(game, {})
      expect(decouple.trigger).toHaveBeenCalledWith(game, 'new PlayingField', field)

    it "stores block at coordinate", ->
      field = new engine.PlayingField({}, {})
      blk = new engine.Block(field, {}, 1, 2)
      field.storeBlock(blk, [1, 2])
      expect(field.blockFromXy([1, 2])).toBe(blk)

    it "takes away coordinate after storing", ->
      field = new engine.PlayingField({}, {})
      blk = new engine.Block(field, {}, 1, 2)
      expect(field.isXyFree([1, 2])).toBeTruthy()
      expect(field.isXyTaken([1, 2])).toBeFalsy()
      field.storeBlock(blk, [1, 2])
      expect(field.isXyTaken([1, 2])).toBeTruthy()
      expect(field.isXyFree([1, 2])).toBeFalsy()

# TODO: Test piece move, piece transform, and clearing lines.

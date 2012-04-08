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

    it "triggers move block event when setting xy", ->
      blk = new engine.Block({}, {}, 1, 2)
      spyOn(decouple, 'trigger')
      blk.setXy([3, 4])
      expect(decouple.trigger).toHaveBeenCalledWith(blk, 'move Block')


  describe 'tetromino-engine PlayingField', ->

    describe 'when instantiating', ->

      it "triggers new playing field event", ->
        spyOn(decouple, 'trigger')
        game = {}
        field = new engine.PlayingField(game, {})
        expect(decouple.trigger).toHaveBeenCalledWith(game, 'new PlayingField', field)

      it "triggers new block event for each new block and one for new piece", ->
        blk1 = new engine.Block({}, { type: 0 }, 1, 2)
        blk2 = new engine.Block({}, { type: 0 }, 2, 3)
        piece = { blocks: [blk1, blk2], type: 0 }
        spyOn(decouple, 'trigger')
        field = new engine.PlayingField({}, { curFloating: piece })
        expect(decouple.trigger).toHaveBeenCalledWith(field, 'new Block', blk1)
        expect(decouple.trigger).toHaveBeenCalledWith(field, 'new Block', blk2)
        expect(decouple.trigger).toHaveBeenCalledWith(field, 'new FloatingBlock', field.curFloating)

    describe 'when committing new piece', ->

      it "stores new piece", ->
        blk1 = new engine.Block({}, {}, 1, 2)
        blk2 = new engine.Block({}, {}, 2, 3)
        piece = { blocks: [blk1, blk2] }
        field = new engine.PlayingField({}, {})
        field.commitNewPiece('nextFloating', piece)
        expect(field.nextFloating).toBe(piece)

      it "triggers new block event for each new block and one for new piece", ->
        field = new engine.PlayingField({}, {})
        blk1 = new engine.Block({}, { type: 0 }, 1, 2)
        blk2 = new engine.Block({}, { type: 0 }, 2, 3)
        piece = new engine.FloatingBlock(field, { blocks: [blk1, blk2], type: 0 })
        spyOn(decouple, 'trigger')
        field.commitNewPiece('nextFloating', piece)
        expect(decouple.trigger).toHaveBeenCalledWith(field, 'new Block', blk1)
        expect(decouple.trigger).toHaveBeenCalledWith(field, 'new Block', blk2)
        expect(decouple.trigger).toHaveBeenCalledWith(field, 'new FloatingBlock', field.nextFloating)

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

    it "pushes current piece up when shifting lines up", ->
      field = new engine.PlayingField({}, {})
      # Put blocks at the bottom.
      fieldBlk = new engine.Block(field, {}, 1, 9)
      field.storeBlock(fieldBlk, fieldBlk.getXy())
      # Put piece next to the bottom.
      pieceBlk = new engine.Block(field, {}, 1, 8)
      field.curFloating = new engine.FloatingBlock(field, { blocks: [pieceBlk] })
      field.shiftLinesUp(2)
      expect(field.blockFromXy([1, 7])).toBe(fieldBlk)
      expect(field.blockFromXy([1, 8])).toBeNull()
      expect(field.blockFromXy([1, 9])).toBeNull()
      expect(field.curFloating.blocks[0].getXy()).toEqual([1, 6])

# TODO: Test piece move, piece transform, and clearing lines.

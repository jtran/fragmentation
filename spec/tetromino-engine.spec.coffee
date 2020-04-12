`import decouple from '../lib/decouple.js'`
`import engine from '../lib/tetromino-engine.js'`

describe 'tetromino-engine Block', ->

  it "constructs new block with given x and y", ->
    blk = new engine.Block({}, {}, 1, 2)
    expect(blk.x).to.equal 1
    expect(blk.y).to.equal 2

  it "triggers move block event when setting xy", ->
    blk = new engine.Block({}, {}, 1, 2)
    spyOn(decouple, 'trigger')
    blk.setXy([3, 4])
    expect(decouple.trigger).to.have.been.calledWith(blk, 'move Block')
    decouple.trigger.restore()

describe 'tetromino-engine PlayingField', ->

  describe 'when instantiating', ->

    it "triggers new playing field event", ->
      spyOn(decouple, 'trigger')
      game = {}
      field = new engine.PlayingField(game, {})
      expect(decouple.trigger).to.have.been.calledWith(game, 'new PlayingField', field)
      decouple.trigger.restore()

    it "triggers new block event for each new block and one for new piece", ->
      blk1 = new engine.Block({}, { type: 0 }, 1, 2)
      blk2 = new engine.Block({}, { type: 0 }, 2, 3)
      piece = { blocks: [blk1, blk2], type: 0 }
      spyOn(decouple, 'trigger')
      field = new engine.PlayingField({}, { curFloating: piece })
      expect(decouple.trigger).to.have.been.calledWith(field, 'new Block', blk1)
      expect(decouple.trigger).to.have.been.calledWith(field, 'new Block', blk2)
      expect(decouple.trigger).to.have.been.calledWith(field, 'new FloatingBlock', field.curFloating)
      decouple.trigger.restore()

  describe 'when committing new piece', ->

    it "stores new piece", ->
      blk1 = new engine.Block({}, {}, 1, 2)
      blk2 = new engine.Block({}, {}, 2, 3)
      piece = { blocks: [blk1, blk2] }
      field = new engine.PlayingField({}, {})
      field.commitNewPiece('nextFloating', piece)
      expect(field.nextFloating).to.equal(piece)

    it "triggers new block event for each new block and one for new piece", ->
      field = new engine.PlayingField({}, {})
      blk1 = new engine.Block({}, { type: 0 }, 1, 2)
      blk2 = new engine.Block({}, { type: 0 }, 2, 3)
      piece = new engine.FloatingBlock(field, { blocks: [blk1, blk2], type: 0 })
      spyOn(decouple, 'trigger')
      field.commitNewPiece('nextFloating', piece)
      expect(decouple.trigger).to.have.been.calledWith(field, 'new Block', blk1)
      expect(decouple.trigger).to.have.been.calledWith(field, 'new Block', blk2)
      expect(decouple.trigger).to.have.been.calledWith(field, 'new FloatingBlock', field.nextFloating)
      decouple.trigger.restore()

  it "stores block at coordinate", ->
    field = new engine.PlayingField({}, {})
    blk = new engine.Block(field, {}, 1, 2)
    field.storeBlock(blk, [1, 2])
    expect(field.blockFromXy([1, 2])).to.equal(blk)

  it "takes away coordinate after storing", ->
    field = new engine.PlayingField({}, {})
    blk = new engine.Block(field, {}, 1, 2)
    expect(field.isXyFree([1, 2])).to.be.true
    expect(field.isXyTaken([1, 2])).to.be.false
    field.storeBlock(blk, [1, 2])
    expect(field.isXyTaken([1, 2])).to.be.true
    expect(field.isXyFree([1, 2])).to.be.false

  it "pushes current piece up when shifting lines up", ->
    field = new engine.PlayingField({}, {})
    # Put blocks at the bottom.
    fieldBlk = new engine.Block(field, {}, 1, 9)
    field.storeBlock(fieldBlk, fieldBlk.getXy())
    # Put piece next to the bottom.
    pieceBlk = new engine.Block(field, {}, 1, 8)
    field.curFloating = new engine.FloatingBlock(field, { blocks: [pieceBlk] })
    field.shiftLinesUp(2)
    expect(field.blockFromXy([1, 7])).to.equal(fieldBlk)
    expect(field.blockFromXy([1, 8])).to.equal(null)
    expect(field.blockFromXy([1, 9])).to.equal(null)
    expect(field.curFloating.blocks[0].getXy()).to.have.ordered.members([1, 6])

# TODO: Test piece move, piece transform, and clearing lines.

import decouple from '../lib/decouple.js'
import engine from '../lib/tetromino-engine.js'

describe 'tetromino-engine Block', ->

  afterEach ->
    decouple.trigger.restore?()

  it "constructs new block with given x and y", ->
    blk = new engine.Block({}, {}, 1, 2)
    expect(blk.x).to.equal 1
    expect(blk.y).to.equal 2

  it "triggers move block event when setting xy", ->
    blk = new engine.Block({}, {}, 1, 2)
    spyOn(decouple, 'trigger')
    blk.setXy([3, 4])
    expect(decouple.trigger).to.have.been.calledWith(blk, 'move Block')

  it "updates isActivated and triggers activate event", ->
    blk = new engine.Block({}, {}, 1, 2)
    spyOn(decouple, 'trigger')
    blk.activate()
    expect(blk.isActivated).to.equal(true)
    expect(decouple.trigger).to.have.been.calledWith(blk, 'isActivatedChange', true)

describe 'tetromino-engine PieceBagGenerator', ->

  it "generates a random sequence without reusing from the bag", ->
    gen = new engine.PieceBagGenerator('test seed')
    vals = (gen.next().value for _ in [1..11])
    expect(vals).to.deep.equal [6, 1, 4, 5, 5, 4, 0, 3, 2, 6, 1]

describe 'tetromino-engine PlayingField', ->

  afterEach ->
    decouple.trigger.restore?()

  describe 'when instantiating', ->

    it "triggers new playing field event", ->
      spyOn(decouple, 'trigger')
      game = {}
      field = new engine.PlayingField(game, {})
      expect(decouple.trigger).to.have.been.calledWith(game, 'newPlayingFieldBeforeInit', field)

    it "copies pieces and their blocks", ->
      blk1 = new engine.Block({}, { type: 0 }, 1, 2)
      blk2 = new engine.Block({}, { type: 0 }, 2, 3)
      piece = { blocks: [blk1, blk2], type: 0 }
      blk3 = new engine.Block({}, { type: 1 }, 4, 5)
      blk4 = new engine.Block({}, { type: 1 }, 6, 7)
      nextPiece = { blocks: [blk3, blk4], type: 1 }
      field = new engine.PlayingField({}, { curFloating: piece, nextFloating: nextPiece })
      # The playing field activates its current blocks.
      blk1.activate()
      blk2.activate()
      expect(field).to.have.deep.nested.property('curFloating.blocks', [blk1, blk2])
      expect(field).to.have.deep.nested.property('nextFloating.blocks', [blk3, blk4])

  describe 'when committing new piece', ->

    it "stores new piece", ->
      blk1 = new engine.Block({}, {}, 1, 2)
      blk2 = new engine.Block({}, {}, 2, 3)
      piece = { blocks: [blk1, blk2] }
      field = new engine.PlayingField({}, {})
      field.commitNewPiece('nextFloating', piece)
      expect(field.nextFloating).to.equal(piece)

    it "triggers add event for each new block and one for the piece", ->
      field = new engine.PlayingField({}, {})
      blk1 = new engine.Block({}, { type: 0 }, 1, 2)
      blk2 = new engine.Block({}, { type: 0 }, 2, 3)
      piece = new engine.FloatingPiece(field, { blocks: [blk1, blk2], type: 0 })
      spyOn(decouple, 'trigger')
      field.commitNewPiece('nextFloating', piece)
      expect(decouple.trigger).to.have.been.calledWith(field, 'addBlock', blk1)
      expect(decouple.trigger).to.have.been.calledWith(field, 'addBlock', blk2)
      expect(decouple.trigger).to.have.been.calledWith(field, 'addPiece', field.nextFloating)

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
    field.curFloating = new engine.FloatingPiece(field, { blocks: [pieceBlk] })
    field.shiftLinesUp(2)
    expect(field.blockFromXy([1, 7])).to.equal(fieldBlk)
    expect(field.blockFromXy([1, 8])).to.equal(null)
    expect(field.blockFromXy([1, 9])).to.equal(null)
    expect(field.curFloating.blocks[0].getXy()).to.have.ordered.members([1, 6])

  describe 'when delaying', ->

    it "shifts ys up", (done) ->
      field = new engine.PlayingField({}, {})
      field.delay 1, [10], (ys) =>
        expect(ys).to.deep.equal [9]
        done()
      field.shiftLinesUp(1)

    it "shifts ys down due to clearing lines below", (done) ->
      field = new engine.PlayingField({}, {})
      field.delay 1, [10], (ys) =>
        expect(ys).to.deep.equal [11]
        done()
      field.shiftLinesDownDueToClear([13])

    it "doesn't shift ys down due to clearing lines above", (done) ->
      field = new engine.PlayingField({}, {})
      field.delay 1, [10], (ys) =>
        expect(ys).to.deep.equal [10]
        done()
      field.shiftLinesDownDueToClear([3])

# TODO: Test piece move, piece transform, and clearing lines.

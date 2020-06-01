import decouple from '../lib/decouple.js'
import { Block, PlayingField } from '../lib/tetromino-engine.js'
import { PlayingFieldView } from '../lib/tetromino-push-to-server-view.js'

describe 'tetromino-push-to-server-view PlayingFieldView', ->

  describe 'when instantiating', ->

    it "does not throw an exception", ->
      game = {}
      socket = {}
      blk1 = new Block({}, { type: 0 }, 1, 2)
      piece = { blocks: [blk1], type: 0 }
      blk2 = new Block({}, { type: 1 }, 3, 4)
      nextPiece = { blocks: [blk2], type: 1 }
      blk3 = new Block({}, { type: 3 }, 5, 6)
      field = new PlayingField(game, { curFloating: piece, nextFloating: nextPiece })
      field.storeBlock(blk3, blk3.getXy())
      new PlayingFieldView(game, field, socket)
      # TODO: Check something more interesting.

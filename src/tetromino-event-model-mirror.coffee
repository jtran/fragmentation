define ['tetromino-player', 'decouple', 'underscore'], (tetrominoPlayer, decouple, _) ->

  # If you have a model with a TetrominoPushToServerView, this class
  # can create another model that mirrors the original, allowing us to
  # have a local instance of the remote model.
  class Mirror
    # players is a hash : playerId -> Player.  FloatingBlock
    # constructor is required to prevent circular dependency between
    # this module and the engine.
    constructor: (@players, @FloatingBlock) ->

    receiveBlockEvent: (playerId, blockId, event, args...) ->
      #console.log 'receiveBlockEvent', playerId, blockId, event, args...
      block = @players[playerId].field.blockFromId(blockId)
      if not block
        console.log 'receiveBlockEvent', playerId, blockId, event, args...
        throw "couldn't find block #{blockId}"
      #console.log block.id, block
      if event == 'move Block'
        block.setXy(args[0])
      else
        decouple.trigger(block, event, args...)

    receiveFieldEvent: (playerId, event, args...) ->
      console.log 'receiveFieldEvent', playerId, event, args...
      field = @players[playerId].field
      if event == 'afterLandPiece'
        console.log 'receive afterLandPiece', (b.id for b in field.curFloating.blocks), playerId
        for blk in field.curFloating.blocks
          field.storeBlock(blk, blk.getXy())
      else if event == 'new FloatingBlock'
        [opts] = args
        field.curFloating = field.nextFloating
        field.nextFloating = new @FloatingBlock(field, _.extend(opts, { playerId: playerId }))
        for blk in field.curFloating.blocks
          decouple.trigger(blk, 'activate Block')
      else if event == 'clear'
        [ys, blks] = args
        field.clearLinesSequence(ys)
      else
        decouple.trigger(field, event, args...)


  # Exports
  root = exports ? this
  root.TetrominoEventModelMirror =
    Mirror: Mirror

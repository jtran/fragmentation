import decouple from './decouple.js'

export class BlockView
  constructor: (@blockModel, @game, @socket) ->
    # Block model objects have no identity when pushed over the
    # wire.  So instead, we push a blockId to identify a block which
    # persists for the life of a game.
    decouple.on @blockModel, 'move Block', @, (caller, event) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeBlockEvent', @game.localPlayer.id, @blockModel.id, event, @blockModel.getXy())

    decouple.on @blockModel, 'removeBlock', @, (caller, event) => @dispose()

  dispose: ->
    # Remove references to prevent memory leak.
    decouple.removeAllForTarget(@)


# View of a PlayingField model that pushes updates to the server.
export class PlayingFieldView
  constructor: (@game, @fieldModel, @socket) ->
    if @fieldModel.curFloating?
      new BlockView(blk, @game, @socket) for blk in @fieldModel.curFloating.blocks
    if @fieldModel.nextFloating?
      new BlockView(blk, @game, @socket) for blk in @fieldModel.nextFloating.blocks
    for row in @fieldModel.blocks
      for blk in row when blk?
        new BlockView(blk, @game, @socket)

    decouple.on @fieldModel, 'stateChange', @, (caller, event, newState) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', @game.localPlayer.id, event, newState)

    decouple.on @fieldModel, 'addBlock', @, (caller, event, block) =>
      new BlockView(block, @game, @socket)
      # We don't distribute this event because the 'addPiece' or
      # 'addNoiseBlocks' event handles it.

    decouple.on @fieldModel, 'addNoiseBlocks', @, (caller, event, n, blocks) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', @game.localPlayer.id, event, n, blocks)

    decouple.on @fieldModel, 'addPiece', @, (caller, event, piece) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', @game.localPlayer.id, event, piece.asJson())

    decouple.on @fieldModel, 'clear', @, (caller, event, ys, blksToRemove) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', @game.localPlayer.id, event, ys, blksToRemove)

    decouple.on @fieldModel, 'afterAttachPiece', @, (caller, event) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', @game.localPlayer.id, event)

  # Note: This currently never gets called because we only ever instantiate one
  # push-to-server-view and never destroy it.
  dispose: ->
    # TODO: Dispose block views.  We don't keep references to them.
    decouple.removeAllForTarget(@)

export default { BlockView, PlayingFieldView }

import decouple from './decouple.js'

export class BlockView
  constructor: (@blockModel, @game, @socket) ->
    # Block model objects have no identity when pushed over the
    # wire.  So instead, we push a blockId to identify a block which
    # persists for the life of a game.
    decouple.on @blockModel, 'move Block', (caller, event) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeBlockEvent', @blockModel.id, event, @blockModel.getXy())

  dispose: ->
    # Remove references to prevent memory leak.
    decouple.removeAllForCaller(@blockModel)


# View of a PlayingField model that pushes updates to the server.
export class PlayingFieldView
  constructor: (@game, @fieldModel, @socket) ->
    decouple.on @fieldModel, 'stateChange', (caller, event, newState) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', event, newState)

    decouple.on @fieldModel, 'new Block', (caller, event, block) =>
      new BlockView(block, @game, @socket)
      # We don't distribute this event because the 'new
      # FloatingBlock' or 'newNoiseBlocks' event handles it.

    decouple.on @fieldModel, 'newNoiseBlocks', (caller, event, n, blocks) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', event, n, blocks)

    decouple.on @fieldModel, 'new FloatingBlock', (caller, event, piece) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', event, piece.asJson())

    decouple.on @fieldModel, 'clear',          (caller, event, ys, blksToRemove) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', event, ys, blksToRemove)

    decouple.on @fieldModel, 'afterAttachPiece', (caller, event) =>
      if @game.joinedRemoteGame
        @socket.emit('distributeFieldEvent', event)

export default { BlockView, PlayingFieldView }

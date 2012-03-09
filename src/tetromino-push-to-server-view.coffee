define ['underscore', 'decouple', 'now'], (_, decouple, now) ->

  class BlockView
    constructor: (@blockModel, @game, @now) ->
      # Block model objects have no identity when pushed over the
      # wire.  So instead, we push a blockId to identify a block which
      # persists for the life of a game.
      decouple.on @blockModel, 'move Block', (caller, event) =>
        if @game.joinedRemoteGame
          @now.distributeBlockEvent(@blockModel.id, event, @blockModel.getXy())

      decouple.on @blockModel, 'afterClear Block', (caller, event) =>
        @now.distributeBlockEvent(@blockModel.id, event) if @game.joinedRemoteGame
        @dispose()

    dispose: ->
      # Remove references to prevent memory leak.
      decouple.removeAllForCaller(@blockModel)


  # View of a PlayingField model that pushes updates to the server.
  class PlayingFieldView
    constructor: (@game, @fieldModel, @now) ->
      decouple.on @fieldModel, 'new Block', (caller, event, block, piece) =>
        new BlockView(block, @game, @now)
        # We don't distribute this event because the 'new
        # FloatingBlock' event handles it.

      decouple.on @fieldModel, 'new FloatingBlock', (caller, event, piece) =>
        if @game.joinedRemoteGame
          @now.distributeFieldEvent(event, piece.asJson())

      decouple.on @fieldModel, 'clear',          (caller, event, ys, blksToRemove) =>
        if @game.joinedRemoteGame
          @now.distributeFieldEvent(event, ys, blksToRemove)

      decouple.on @fieldModel, 'afterLandPiece', (caller, event) =>
        if @game.joinedRemoteGame
          @now.distributeFieldEvent(event)

    push: ->
      throw "someone called push()"
      return unless @game.joinedRemoteGame
      console.log "pushing playing field...", @fieldModel.asJson()
      @now.updatePlayingField(@fieldModel.asJson())


  # Exports
  root = exports ? this
  root.TetrominoPushToServerView =
    PlayingFieldView: PlayingFieldView

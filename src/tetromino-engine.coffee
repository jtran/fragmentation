define ['underscore', 'util', 'decouple', 'now'], (_, util, decouple, nowjs) ->

  # Represents a single square.
  class Block

    # Need the piece to style it.  After that it's discarded.
    constructor: (field, piece, @x, @y, options = {}) ->
      @id = options.id ? _.uniqueId('b')
      @pieceType = piece.type
      @playerId = field.playerId if field.playerId?
      decouple.trigger(field, 'new Block', @, piece)

    setXy: (xy) ->
      @x = xy[0]
      @y = xy[1]
      decouple.trigger(@, 'move Block')

    getXy: -> [@x, @y]


  class FloatingBlock
    NUM_TYPES_OF_BLOCKS = 7;

    constructor: (@field, options = {}) ->
      @type = options.type ? util.randInt(NUM_TYPES_OF_BLOCKS - 1)
      @canRotate = true
      @blocks = []
      if options.blocks?
        for b in options.blocks
          @blocks.push(new Block(@field, { type: @type }, b.x, b.y, { id: b.id }))
      mid = Math.floor(@field.fieldWidth / 2) - 1
      switch @type
        when 0  # O
          if @blocks.length == 0
            @blocks.push(new Block(@field, @, mid,     0))
            @blocks.push(new Block(@field, @, mid + 1, 0))
            @blocks.push(new Block(@field, @, mid,     1))
            @blocks.push(new Block(@field, @, mid + 1, 1))
          @centerIndex = 0
          @canRotate = false
        when 1  # T
          if @blocks.length == 0
            @blocks.push(new Block(@field, @, mid - 1, 0))
            @blocks.push(new Block(@field, @, mid,     0))
            @blocks.push(new Block(@field, @, mid + 1, 0))
            @blocks.push(new Block(@field, @, mid,     1))
          @centerIndex = 1
        when 2  # S
          if @blocks.length == 0
            @blocks.push(new Block(@field, @, mid + 1, 0))
            @blocks.push(new Block(@field, @, mid,     0))
            @blocks.push(new Block(@field, @, mid,     1))
            @blocks.push(new Block(@field, @, mid - 1, 1))
          @centerIndex = 2
        when 3  # Z
          if @blocks.length == 0
            @blocks.push(new Block(@field, @, mid - 1, 0))
            @blocks.push(new Block(@field, @, mid,     0))
            @blocks.push(new Block(@field, @, mid,     1))
            @blocks.push(new Block(@field, @, mid + 1, 1))
          @centerIndex = 2
        when 4  # L
          if @blocks.length == 0
            @blocks.push(new Block(@field, @, mid - 1, 0))
            @blocks.push(new Block(@field, @, mid,     0))
            @blocks.push(new Block(@field, @, mid + 1, 0))
            @blocks.push(new Block(@field, @, mid - 1, 1))
          @centerIndex = 1
        when 5  # J
          if @blocks.length == 0
            @blocks.push(new Block(@field, @, mid - 1, 0))
            @blocks.push(new Block(@field, @, mid,     0))
            @blocks.push(new Block(@field, @, mid + 1, 0))
            @blocks.push(new Block(@field, @, mid + 1, 1))
          @centerIndex = 1
        when 6  # I
          if @blocks.length == 0
            @blocks.push(new Block(@field, @, mid - 1, 0))
            @blocks.push(new Block(@field, @, mid,     0))
            @blocks.push(new Block(@field, @, mid + 1, 0))
            @blocks.push(new Block(@field, @, mid + 2, 0))
          @centerIndex = 1
        else
          throw "I don't know how to create a floating block of this type: " + @type

      decouple.trigger(@field, 'new FloatingBlock', @)


    asJson: ->
      {
        type: @type
        blocks: @blocks
      }


    # Takes a function that takes single argument the Block to be
    # transformed, which returns the Block's new xy.  Returns true if the
    # transformation was possible.
    transform: (f) ->
      xys2 = (f(blk) for blk in @blocks)
      return false if _(xys2).some(_.bind(@field.isXyTaken, @field))
      _.each(@blocks, (blk, i) ->
        blk.setXy(xys2[i]))
      true

    rotateClockwise: ->
      return false unless @canRotate
      xyCenter = @blocks[@centerIndex].getXy()
      rotateWithShift = (shift) ->
        (blk) ->
          xy = blk.getXy()
          dx = xy[0] - xyCenter[0]
          dy = xy[1] - xyCenter[1]
          [xyCenter[0] - dy + shift, xyCenter[1] + dx]
      @transform(rotateWithShift(0)) ||
        @transform(rotateWithShift(1)) ||
        @transform(rotateWithShift(-1))

    rotateCounterclockwise: ->
      return false unless @canRotate
      xyCenter = @blocks[@centerIndex].getXy()
      rotateWithShift = (shift) ->
        (blk) ->
          xy = blk.getXy()
          dx = xy[0] - xyCenter[0]
          dy = xy[1] - xyCenter[1]
          [xyCenter[0] + dy + shift, xyCenter[1] - dx]
      @transform(rotateWithShift(0)) ||
        @transform(rotateWithShift(1)) ||
        @transform(rotateWithShift(-1))



  class PlayingField
    constructor: (game, options) ->
      @playerId = options.playerId if options.playerId?
      @viewType = options.viewType
      @fieldHeight = 22
      @fieldWidth = 10
      @blocks = []

      @curFloating = null
      @nextFloating = null
      @fallTimer = null

      # Initialize blocks matrix.
      for i in [0 ... @fieldHeight]
        row = []
        row.push(null) for j in [0 ... @fieldWidth]
        @blocks.push(row)

      decouple.trigger(game, 'new PlayingField', @)

      # Initialize blocks after new PlayingField event so that
      # listeners can be installed.
      @curFloating = new FloatingBlock(@, { type: options.curFloating.type, blocks: options.curFloating.blocks, playerId: options.playerId }) if options.curFloating?
      @nextFloating = new FloatingBlock(@, { type: options.nextFloating.type, blocks: options.nextFloating.blocks, playerId: options.playerId }) if options.nextFloating?
      if options.blocks?
        for row in options.blocks
          for b, x in row
            if b
              block = new Block(@, { type: b.pieceType }, b.x, b.y, { id: b.id })
              @storeBlock(block, [b.x, b.y])
              # Activate immediately.
              decouple.trigger(block, 'activate Block')


    # Returns a hash representation of this object with the intent of
    # serializing to JSON.  Will contain no functions and no circular
    # references.  Borrowed from as_json in Rails.
    asJson: ->
      {
        blocks: @blocks
        curFloating: @curFloating.asJson()
        nextFloating: @nextFloating.asJson()
      }


    # The inverse of asJson.  When we have a PlayingField that
    # represents a remote game, a remote client calls asJson, and
    # sends the result to us.  We must then update our representation
    # of their playing field based on it.
    updateFromJson: (field) ->
      console.log 'updateFromJson', field.curFloating
      for row, i in field.blocks
        for blk, j in row
          if blk && not @blocks[i][j]
            block = new Block(@, { type: blk.pieceType }, blk.x, blk.y, { id: blk.id })
            @storeBlock(block, [blk.x, blk.y])
            # Activate immediately.
            decouple.trigger(block, 'activate Block')
          if not blk && @blocks[i][j]
            decouple.trigger(@blocks[i][j], 'afterClear Block')

      null


    blockFromId: (blockId) ->
      for blk in @curFloating.blocks
        return blk if blk?.id == blockId
      for blk in @nextFloating.blocks
        return blk if blk?.id == blockId
      for row in @blocks
        for blk in row
          return blk if blk?.id == blockId
      null


    blockFromXy: (xy) ->
      row = xy[1]
      return null if row < 0 || row >= @blocks.length
      col = xy[0]
      return null if col < 0 || col >= @blocks[row].length
      @blocks[row][col]


    storeBlock: (blk, xy) -> @blocks[xy[1]][xy[0]] = blk


    isXyFree: (xy) ->
      @blockFromXy(xy) == null &&
        xy[0] >= 0 && xy[0] < @fieldWidth &&
        xy[1] >= 0 && xy[1] < @fieldHeight


    isXyTaken: (xy) -> ! @isXyFree(xy)


    moveLeft: ->
      @curFloating.transform((blk) ->
        xy = blk.getXy()
        [xy[0] - 1, xy[1]]
      )

    moveRight: ->
      @curFloating.transform((blk) ->
        xy = blk.getXy()
        [xy[0] + 1, xy[1]]
      )


    moveDown: ->
      @curFloating.transform((blk) ->
        xy = blk.getXy()
        [xy[0], xy[1] + 1]
      )


    landFloatingBlock: (flt) ->
      for blk in flt.blocks
        @storeBlock(blk, blk.getXy())
      null


    # Returns array of y's of lines that need to be cleared.
    linesToClear: (flt) ->
      linesToCheck = _(blk.getXy()[1] for blk in flt.blocks).uniq()
      y for y in linesToCheck when _(@blocks[y]).all(_.identity)


    fillLinesFromAbove: (ys) ->
      return if _.isEmpty(ys)
      shift = 1
      ys.sort()
      for y in [_.last(ys) .. 0]
        shift++ while _.include(ys, y - shift)
        for x in [0 ... @fieldWidth]
          blk = @blockFromXy([x, y - shift])
          blk?.setXy([x, y])
          @storeBlock(blk, [x, y])
      null


    clearLines: (ys) ->
      blksToRemove = []
      for y in ys
        for x in [0 ... @fieldWidth]
          blk = @blocks[y][x]
          @storeBlock(null, [x, y])
          continue unless blk
          blksToRemove.push(blk)
      decouple.trigger(@, 'clear', ys, blksToRemove)
      null


    clearLinesSequence: (ys) ->
      return false if ys.length == 0
      @clearLines(ys)
      _.delay((=>
        @fillLinesFromAbove(ys)
        if ! @checkForGameOver()
          @startGravity()
      ), 500)
      true


    showNewFloatingBlock: ->
      # The first time this is called, next will be null.
      if ! @nextFloating
        @nextFloating = new FloatingBlock(this)

      # Make next be current.
      @curFloating = @nextFloating
      # Move the new current into position.
      for blk in @curFloating.blocks
        decouple.trigger(blk, 'activate Block')
        blk.setXy([blk.x, blk.y + 2])
      # Spawn a new next.
      @nextFloating = new FloatingBlock(this)
      null


    # Returns true if game is over.
    checkForGameOver: ->
      return false if _(blk.getXy() for blk in @curFloating.blocks).all(_.bind(@isXyFree, this))
      @stopGravity()

      decouple.trigger(@, 'gameOver')

      true


    fall: ->
      fell = @moveDown()
      if ! fell
        decouple.trigger(@, 'beforeLandPiece')
        @landFloatingBlock(@curFloating)
        decouple.trigger(@, 'afterLandPiece')
        ysToClear = @linesToClear(@curFloating)
        clearedLines = ysToClear.length > 0
        if clearedLines
          # Lines were cleared.  Pause the game timer.
          @stopGravity()
        @showNewFloatingBlock()
        @clearLinesSequence(ysToClear)
        if not clearedLines && @checkForGameOver()
          return false
      fell


    drop: ->
      decouple.trigger(@, 'beforeDrop')

      # Drop.
      null while @fall()

      decouple.trigger(@, 'afterDrop')


    gravityInterval: -> 700


    startGravity: ->
      @fallTimer = window.setInterval(_.bind(@fall, @), @gravityInterval())


    stopGravity: ->
      window.clearInterval(@fallTimer)
      @fallTimer = null



  # A game on the client.
  class TetrominoGame
    constructor: (@now) ->
      @joinedRemoteGame = false
      @localField = null
      @localPlayer = null
      @players = {}
      @addLocalPlayer()
      game = @
      @now.ready =>
        @setLocalPlayerId(@now.core.clientId)
        @now.receiveMessage = (playerId, msg) -> console.log "#{game.players[playerId].name}: #{msg}"
        @now.addPlayer = _.bind(@addRemotePlayer, @)
        @now.removePlayer = _.bind(@removePlayer, @)
        @now.receiveBlockEvent = _.bind(@receiveBlockEvent, @)
        @now.receiveFieldEvent = _.bind(@receiveFieldEvent, @)
        @now.updateRemotePlayingField = _.bind(@updateRemotePlayingField, @)
        @now.getPlayers (players) =>
          console.log 'getPlayers', players
          @addRemotePlayer(p) for id, p of players
          @now.join(@localField.asJson())
          @joinedRemoteGame = true

    addLocalPlayer: (player = {}) ->
      throw("You tried to add a local player, but I already have one.") if @localField
      @localField = player.field = new PlayingField(@, { viewType: 'local' })
      @localPlayer = player
      @addPlayer(player) if player.id
      @localPlayer

    setLocalPlayerId: (id) ->
      console.log 'setLocalPlayerId', id
      @removePlayer(@localPlayer.id) if @localPlayer.id
      @localPlayer.id = id
      @addPlayer(@localPlayer)

    addRemotePlayer: (player) ->
      return if player.id in _.keys(@players, 'id')
      player.field = new PlayingField(@, { playerId: player.id, viewType: 'remote', blocks: player.field.blocks, curFloating: player.field.curFloating, nextFloating: player.field.nextFloating })
      console.log 'addRemotePlayer', (b.id for b in player.field.curFloating.blocks), player.id
      @addPlayer(player)

    # player must have an id.
    addPlayer: (player) ->
      console.log("addPlayer", player.id)
      @players[player.id] = player

    removePlayer: (playerId) ->
      id = playerId.id ? playerId
      console.log("removePlayer", id)
      player = @players[id]
      decouple.trigger(@, 'beforeRemovePlayer', player)
      delete @players[id]
      decouple.trigger(@, 'afterRemovePlayer', player)

    receiveBlockEvent: (playerId, blockId, event, args...) ->
      return if playerId == @localPlayer.id
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
      return if playerId == @localPlayer.id
      console.log 'receiveFieldEvent', playerId, event, args...
      field = @players[playerId].field
      if event == 'afterLandPiece'
        console.log 'receive afterLandPiece', (b.id for b in field.curFloating.blocks), playerId
        for blk in field.curFloating.blocks
          field.storeBlock(blk, blk.getXy())
      else if event == 'new FloatingBlock'
        [opts] = args
        field.curFloating = field.nextFloating
        field.nextFloating = new FloatingBlock(field, _.extend(opts, { playerId: playerId }))
        for blk in field.curFloating.blocks
          decouple.trigger(blk, 'activate Block')
      else if event == 'clear'
        [ys, blks] = args
        field.clearLinesSequence(ys)
      else
        decouple.trigger(field, event, args...)

    # The server calls this when a player has an update to his/her
    # playing field.
    updateRemotePlayingField: (playerId, field) ->
      player = @players[playerId]
      return unless player
      console.log("updateRemotePlayingField #{playerId}", field)
      player.field.updateFromJson(field) if playerId != @localPlayer.id

    start: ->
      @localField?.startGravity()



  # Exports
  root = exports ? this
  root.TetrominoEngine =
    Block: Block
    FloatingBlock: FloatingBlock
    PlayingField: PlayingField
    TetrominoGame: TetrominoGame

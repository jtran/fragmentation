import _ from './underscore.js'
import util from './util.js'
import { Player }  from './tetromino-player.js'
import decouple from './decouple.js'

# Represents a single square.
export class Block

  # Need the piece to style it.  After that it's discarded.
  constructor: (field, piece, @x, @y, options = {}) ->
    @id = options.id ? _.uniqueId('b')
    @pieceType = piece.type
    @playerId = field.playerId if field.playerId?
    @isActivated = options.isActivated ? false

  setXy: ([@x, @y]) ->
    decouple.trigger(@, 'move Block')

  getXy: -> [@x, @y]

  activate: ->
    @isActivated = true
    decouple.trigger(@, 'isActivatedChange', @isActivated)
    @isActivated


export class FloatingPiece
  NUM_TYPES_OF_BLOCKS = 7

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
        throw new Error("I don't know how to create a floating block of this type: " + @type)

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
    return false if _(xys2).some(@field.isXyTaken)
    for blk, i in @blocks
      blk.setXy(xys2[i])
    true

  moveLeft:  -> @transform (blk) -> [blk.x - 1, blk.y]
  moveRight: -> @transform (blk) -> [blk.x + 1, blk.y]
  moveDown:  -> @transform (blk) -> [blk.x,     blk.y + 1]
  moveUp:    -> @transform (blk) -> [blk.x,     blk.y - 1]

  moveToX: (x) ->
    curX = => @blocks[@centerIndex].x
    if (curX() < x)
      null while @moveRight() && curX() < x
      return true
    else if (x < curX())
      null while @moveLeft() && x < curX()
      return true
    false

  rotateClockwise: ->
    return false unless @canRotate
    [xCenter, yCenter] = @blocks[@centerIndex].getXy()
    rotateWithShift = (shift) ->
      (blk) ->
        dx = blk.x - xCenter
        dy = blk.y - yCenter
        [xCenter - dy + shift, yCenter + dx]
    @transform(rotateWithShift(0)) ||
      @transform(rotateWithShift(1)) ||
      @transform(rotateWithShift(-1))

  rotateCounterclockwise: ->
    return false unless @canRotate
    [xCenter, yCenter] = @blocks[@centerIndex].getXy()
    rotateWithShift = (shift) ->
      (blk) ->
        dx = blk.x - xCenter
        dy = blk.y - yCenter
        [xCenter + dy + shift, yCenter - dx]
    @transform(rotateWithShift(0)) ||
      @transform(rotateWithShift(1)) ||
      @transform(rotateWithShift(-1))



export class PlayingField
  @STATE_PLAYING = STATE_PLAYING = 0
  @STATE_PAUSED = STATE_PAUSED = 1
  @STATE_GAMEOVER = STATE_GAMEOVER = 2

  constructor: (game, options, @DEBUG = false) ->
    @playerId = options.playerId if options.playerId?
    @viewType = options.viewType
    # No gravity on the server.  It gets enabled locally by the game.
    @useGravity = false
    @fieldHeight = 22
    @fieldWidth = 10
    @blocks = []

    @curFloating = null
    @nextFloating = null
    @fallTimer = null

    @state = options.state ? STATE_PLAYING

    # Initialize blocks matrix.
    for i in [0 ... @fieldHeight]
      row = []
      row.push(null) for j in [0 ... @fieldWidth]
      @blocks.push(row)

    decouple.trigger(game, 'newPlayingFieldBeforeInit', @)

    useDebugFill = @viewType == 'local' and @DEBUG
    if useDebugFill
      for i in [0 ... @fieldHeight] when i > @fieldHeight - 5
        for j in [0 ... @fieldWidth] when j != 0
          blk = new Block(@, { type: 'opponent' }, j, i)
          @storeBlock(blk, blk.getXy())
          blk.activate()

    copyPiece = (piece) =>
      new FloatingPiece @,
        type: piece.type
        blocks: piece.blocks
        playerId: options.playerId

    if options.curFloating?
      @curFloating = copyPiece(options.curFloating)
      # Activate immediately.
      blk.activate() for blk in @curFloating.blocks
    if options.nextFloating?
      @nextFloating = copyPiece(options.nextFloating)
    if options.blocks?
      for row in options.blocks
        for b, x in row when b
          block = new Block(@, { type: b.pieceType }, b.x, b.y, { id: b.id })
          @storeBlock(block, [b.x, b.y])
          # Activate immediately.
          block.activate()


  # Returns a hash representation of this object with the intent of
  # serializing to JSON.  Will contain no functions and no circular
  # references.  Borrowed from as_json in Rails.
  asJson: ->
    {
      state: @state
      blocks: @blocks
      curFloating: @curFloating.asJson()
      nextFloating: @nextFloating.asJson()
    }

  # True inverse of asJson.
  @fromJson = (playerId, game, fieldHash) ->
    new PlayingField(game, Object.assign(fieldHash, { playerId: playerId, viewType: 'remote' }))

  # Stores piece in key and triggers events.
  commitNewPiece: (key, piece) ->
    @[key] = piece
    decouple.trigger(@, 'addBlock', blk) for blk in piece.blocks
    decouple.trigger(@, 'addPiece', piece)
    piece

  allBlocks: ->
    bs = (@curFloating.blocks ? []).concat(@nextFloating.blocks ? [])
    bs = bs.concat(row) for row in @blocks
    b for b in bs when b?

  blockFromId: (blockId) ->
    return blk for blk in @allBlocks() when blk.id == blockId
    null


  blockFromXy: ([x, y]) ->
    return null unless 0 <= y < @blocks.length
    return null unless 0 <= x < @blocks[y].length
    @blocks[y][x]

  storeBlock: (blk, [x, y]) ->
    @blocks[y][x] = blk if 0 <= y <= @fieldHeight
    blk

  isXyFree: (xy) =>
    [x, y] = xy
    @blockFromXy(xy) == null &&
      0 <= x < @fieldWidth &&
      0 <= y < @fieldHeight

  isXyTaken: (xy) => ! @isXyFree(xy)

  moveBlock: (xy, xyPrime) ->
    blk = @blockFromXy(xy)
    blk?.setXy(xyPrime)
    @storeBlock(null, xy)
    @storeBlock(blk, xyPrime) if 0 <= xyPrime[1] < @fieldHeight
    blk

  acceptingMoveInput: -> @state == STATE_PLAYING

  rotateClockwise: ->
    return false unless @acceptingMoveInput()
    @curFloating.rotateClockwise()

  rotateCounterclockwise: ->
    return false unless @acceptingMoveInput()
    @curFloating.rotateCounterclockwise()

  moveLeft: ->
    return false unless @acceptingMoveInput()
    @curFloating.moveLeft()

  moveRight: ->
    return false unless @acceptingMoveInput()
    @curFloating.moveRight()

  moveDown: ->
    return false unless @acceptingMoveInput()
    @curFloating.moveDown()

  moveToX: (x) ->
    return false unless @acceptingMoveInput()
    @curFloating.moveToX(x)

  attachPiece: (piece) ->
    return false unless @acceptingMoveInput()
    for blk in piece.blocks
      @storeBlock(blk, blk.getXy())
    null


  # Returns array of y's of lines that need to be cleared.
  linesToClear: (piece) ->
    linesToCheck = util.unique(blk.y for blk in piece.blocks)
    linesToCheck.filter (y) => @blocks[y].every((blk) -> blk?)

  fillLinesFromAbove: (ys) ->
    return if _.isEmpty(ys)
    shift = 1
    ys.sort()
    for y in [_.last(ys) .. 0]
      shift++ while y - shift in ys
      for x in [0 ... @fieldWidth]
        @moveBlock([x, y - shift], [x, y])
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

  clearLinesSequence: (ys, callback = null) ->
    return false if ys.length == 0
    @clearLines(ys)
    _.delay((=>
      @fillLinesFromAbove(ys)
      callback?()
    ), 500)
    true

  shiftLinesUp: (n) ->
    return if n <= 0
    for y in [n ... @fieldHeight]
      for x in [0 ... @fieldWidth]
        fieldBlk = @blockFromXy([x, y])
        yPrime = y - n
        # If the current piece occupies any coordinate we're moving
        # through, push the piece up.
        if fieldBlk
          while @curFloating.blocks.some((blk) -> blk.x == x && blk.y in [y..yPrime])
            break if not @curFloating.moveUp()
        @moveBlock([x, y], [x, yPrime])

  fillBottomLinesWithNoise: (n) ->
    return if n <= 0
    n = Math.min(n, @fieldHeight)
    numGaps = Math.ceil(0.3 * @fieldWidth)
    newBlocks = _.flatten(
      for i in [1 .. n]
        y = @fieldHeight - i
        xs = [0 ... @fieldWidth]
        # TODO: Remove current piece block positions.
        xs.splice(x, 1) for x in xs when @isXyTaken([x, y])
        xs.splice(util.randInt(xs.length), 1) for g in [1 .. numGaps]
        for x in xs
          blk = new Block(@, { type: 'opponent' }, x, y)
          decouple.trigger(@, 'addBlock', blk)
          @storeBlock(blk, [x, y])
          blk.activate()
          blk
    )
    decouple.trigger(@, 'addNoiseBlocks', n, newBlocks)

  addLinesSequence: (n, createNoise, callback = null) ->
    @shiftLinesUp(n)
    _.delay((=>
      @fillBottomLinesWithNoise(n) if createNoise
      callback?()
    ), 500)

  useNextPiece: ->
    opts = {type: 6} if @DEBUG # debug mode always long
    # The first time this is called, next will be null.
    if ! @nextFloating
      @commitNewPiece('nextFloating', new FloatingPiece(@, opts))

    # Make next be current.
    @curFloating = @nextFloating
    # Move the new current into position.
    for blk in @curFloating.blocks
      blk.activate()
      blk.setXy([blk.x, blk.y + 2])
    # Spawn a new next.
    @commitNewPiece('nextFloating', new FloatingPiece(@, opts))
    null

  # Returns true if game is over.
  checkForGameOver: ->
    if (blk.getXy() for blk in @curFloating.blocks).every(@isXyFree)
      return false

    @stopGravity()

    @state = STATE_GAMEOVER
    decouple.trigger(@, 'stateChange', @state)

    true

  moveDownOrAttach: =>
    return false unless @acceptingMoveInput()
    fell = @moveDown()
    if ! fell
      decouple.trigger(@, 'beforeAttachPiece')
      @attachPiece(@curFloating)
      decouple.trigger(@, 'afterAttachPiece')
      ysToClear = @linesToClear(@curFloating)
      clearedLines = ysToClear.length > 0
      if clearedLines
        # Lines were cleared.  Pause gravity.
        @stopGravity()
        # Transfer control to next piece so player can get a head
        # start.
        @useNextPiece()
        @clearLinesSequence ysToClear, =>
          if ! @checkForGameOver()
            @startGravity()
      else
        @useNextPiece()
        return false if @checkForGameOver()
    fell

  drop: ->
    return false unless @acceptingMoveInput()

    decouple.trigger(@, 'beforeDrop')

    # Drop.
    null while @moveDownOrAttach()

    decouple.trigger(@, 'afterDrop')

  isPlaying: -> @state == STATE_PLAYING
  isPaused: -> @state == STATE_PAUSED

  pause: ->
    return false unless @state == STATE_PLAYING
    # This isn't perfect.  A user can essentially stop gravity by continually
    # pausing and resuming, but we don't really care.
    @stopGravity()
    @state = STATE_PAUSED
    decouple.trigger(@, 'stateChange', @state)
    true

  resume: ->
    return false unless @state == STATE_PAUSED
    @startGravity()
    @state = STATE_PLAYING
    decouple.trigger(@, 'stateChange', @state)
    true

  togglePause: ->
    switch @state
      when STATE_GAMEOVER then false
      when STATE_PLAYING then @pause()
      when STATE_PAUSED then @resume()
      else throw new Error("Tried to toggle pause while in an unknown game state")

  gravityInterval: -> 700

  startGravity: ->
    return unless @useGravity
    return if @fallTimer?
    @fallTimer = window.setInterval(@moveDownOrAttach, @gravityInterval())

  stopGravity: ->
    return unless @useGravity && @fallTimer?
    window.clearInterval(@fallTimer)
    @fallTimer = null

  setUseGravity: (@useGravity) ->
    return @useGravity unless @isPlaying()
    if @useGravity
      @startGravity()
    else
      @stopGravity()
    @useGravity


# If you have a model with a TetrominoPushToServerView, this class
# can create another model that mirrors the original, allowing us to
# have a local instance of the remote model.
export class ModelEventReceiver
  # players is a Map : playerId -> Player
  constructor: (@game, @localPlayerId = null) ->
    @players = new Map()

  # player : Player | playerHash (returned from Player::asJson())
  addPlayer: (player) =>
    existingPlayer = @players.get(player.id)
    if existingPlayer?
      # Existing player got a new socket ID.
      existingPlayer.socketId = player.socketId if player.socketId?
      return
    # Shallow-clone the player since we may modify it, and ensure it's a Player
    # instance.
    field = player.field
    if field not instanceof PlayingField
      field = new PlayingField(@game,
        playerId: player.id
        viewType: 'remote'
        blocks: field.blocks
        curFloating: field.curFloating
        nextFloating: field.nextFloating
        state: field.state
      )
    player = new Player(player.id, player.socketId, field)
    console.log 'addPlayer', (b.id for b in player.field.curFloating.blocks), player.id
    @players.set(player.id, player)
    decouple.trigger(@game, 'addPlayer', player)

  # playerId may be null.
  removePlayer: (playerId, socketId) =>
    console.log("removePlayer", playerId, socketId)
    player = @players.get(playerId) if playerId?
    if not player? and socketId?
      # TODO: Make this a constant time lookup, not linear.
      player = _.find(Array.from(@players.values()), (p) -> p.socketId == socketId)
    unless player?
      console.log "skipping remove; player not found", playerId, socketId
      return
    if player.id == @localPlayerId
      console.log "skipping remove of local player", player.id
      return
    decouple.trigger(@game, 'beforeRemovePlayer', player)
    @players.delete(player.id)
    decouple.trigger(@game, 'afterRemovePlayer', player)

  receiveBlockEvent: (playerId, blockId, event, args...) =>
    return if playerId == @localPlayerId
    #console.log 'receiveBlockEvent', playerId, blockId, event, args...
    player = @players.get(playerId)
    unless player
      return if not @game.joinedRemoteGame
      throw new Error("couldn't find player #{playerId} for block event #{blockId}")
    block = player.field.blockFromId(blockId)
    if not block
      console.warn 'receiveBlockEvent', playerId, blockId, event, args...
      console.log 'field', player.field, player.field.curFloating, player.field.nextFloating
      console.log 'curFloating'
      console.table player.field.curFloating?.blocks
      console.log 'nextFloating'
      console.table player.field.nextFloating?.blocks
      console.log 'blocks'
      console.table player.field.blocks
      if event == 'move Block'
        xy = args[0]
        block = new Block(player.field, { type: 0 }, xy[0], xy[1], id: blockId, isActivated: true)
        console.warn "couldn't find block #{blockId}; fabricating block #{event} block:", block
        decouple.trigger(player.field, 'addBlock', block)
        player.field.storeBlock(block, xy)
        return
      else
        console.error "couldn't find block #{blockId} for unknown event #{event} args=#{args}"
        return
    if event == 'move Block'
      block.setXy(args[0])
    else
      decouple.trigger(block, event, args...)

  receiveFieldEvent: (playerId, event, args...) =>
    return if playerId == @localPlayerId
    console.log 'receiveFieldEvent', playerId, event, args...
    player = @players.get(playerId)
    unless player?
      return if not @game.joinedRemoteGame
      console.error "received field event for unknown player #{playerId}"
      return
    field = player.field
    if event == 'stateChange'
      field.state = args[0]
      decouple.trigger(field, event, args...)
    else if event == 'afterAttachPiece'
      console.log 'receive afterAttachPiece', (b.id for b in field.curFloating.blocks), playerId
      for blk in field.curFloating.blocks
        field.storeBlock(blk, blk.getXy())
    else if event == 'addPiece'
      [opts] = args
      field.curFloating = field.nextFloating
      field.commitNewPiece('nextFloating', new FloatingPiece(field, Object.assign(opts, { playerId: playerId })))
      blk.activate() for blk in field.curFloating.blocks
    else if event == 'addNoiseBlocks'
      # Someone else received noise, and is telling us about their
      # new noise blocks.
      [n, blks] = args
      field.addLinesSequence n, false, =>
        for b in blks
          block = new Block(field, { type: b.pieceType }, b.x, b.y, { id: b.id })
          decouple.trigger(field, 'addBlock', block)
          field.storeBlock(block, block.getXy())
          block.activate()
    else if event == 'clear'
      [ys, blks] = args
      field.clearLinesSequence(ys)
      # Someone else cleared lines, which means they're sending us
      # noise.
      linesSent = if ys.length < 4 then ys.length - 1 else ys.length
      @players.get(@localPlayerId)?.field.addLinesSequence(linesSent, true)
    else
      decouple.trigger(field, event, args...)

  # The server calls this when a player has sent a full refresh to
  # his/her playing field.
  receiveUpdatePlayingField: (playerId, field) =>
    player = @players.get(playerId)
    unless player
      console.warn "I got an updateClient for an unknown player id=#{playerId}"
      return
    console.log("updatePlayingField #{playerId}", field)
    player.field.updateFromJson(field) if playerId != @localPlayerId


export default {
  Block,
  FloatingPiece,
  PlayingField,
  ModelEventReceiver,
}

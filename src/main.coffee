require ['jquery', 'tetromino-engine', 'tetromino-dom-view', 'tetromino-push-to-server-view', 'decouple', 'underscore', 'socket.io-client'], ($, TetrominoEngine, DomView, PushToServerView, decouple, _, socketio) ->

  $ ?= window.$
  game = null
  localField = null
  localFieldView = null
  pushToServerView = null
  fieldViews = []

  # For debugging.
  logStatus = (msg) -> $('#status').prepend("<div>#{msg}</div>")

  socket = socketio()

  decouple.on null, 'new PlayingField', (game, event, field) ->
    console.log("adding DOM view #{fieldViews.length}", event, field)
    options =
      ordinal: fieldViews.length
      themeIndex: if field.viewType == 'local' then 0 else 2
    fieldView = new DomView.PlayingFieldDomView(field, options)
    fieldViews.push(fieldView)
    if field.viewType == 'local'
      # Keep a reference to the local view.
      localFieldView = fieldView
      # Create a push-to-server view on the local playing field.
      pushToServerView = new PushToServerView.PlayingFieldView(game, field, socket)

  fieldViewsFromPlayer = (player) ->
    fieldView for fieldView in fieldViews when fieldView.fieldModel == player.field

  game = new TetrominoEngine.TetrominoGame(socket)
  localField = game.localField

  # Re-organize the view when a player leaves the game.
  decouple.on game, 'afterRemovePlayer', (caller, event, player) =>
    for fieldView in fieldViewsFromPlayer(player)
      fieldView.leaveGame? =>
        # Remove from list.
        fieldViews = (fv for fv in fieldViews when fv != fieldView)
        # Set ordinals of remaining views.
        i = 0
        for id, p of game.players()
          for fv in fieldViewsFromPlayer(p)
            fv.setOrdinal(i)
          i++

  $(document).bind 'keydown', (event) ->
    # console.log('keydown', event.which, String.fromCharCode(event.which))
    localField.moveLeft()  if (event.which == 37) # left arrow
    localField.moveRight() if (event.which == 39) # right arrow
    localField.moveDownOrAttach()       if (event.which == 40) # down arrow
    localField.drop()      if (event.which == 191) # slash
    letter = String.fromCharCode(event.which).toLowerCase()
    localField.rotateClockwise()        if (letter == 'f')
    localField.rotateCounterclockwise() if (letter == 'd')
    localField.drop() if (letter == 'c')

  ##############################
  # Touch interface.

  touchData = null

  currentPieceX = -> localField.curFloating.blocks[localField.curFloating.centerIndex].x
  currentPieceY = -> localField.curFloating.blocks[localField.curFloating.centerIndex].y

  handleHorizontalSwipe = (e) ->
    x0 = touchData.pieceInitX
    x1 = currentPieceX()
    distDiff = Math.floor(e.totalDeltaX / 20)
    #logStatus "#{e.distance} #{e.totalDeltaX} #{distDiff} #{x0} #{x1}"
    localField.moveToX(x0 + distDiff)

  handleSwipeDown = (e) ->
    #logStatus "begin down #{e.distance} #{e.distance}"
    y0 = touchData.pieceInitY
    y1 = currentPieceY()
    distDiff = Math.floor(e.distance / 20)
    yDiff = (y0 + distDiff) - y1
    #logStatus "#{e.distance} #{e.distance} #{distDiff} #{y0} #{y1}"
    while localField.curFloating == touchData.piece && localField.moveDown() && yDiff >= 0
      yDiff--

  handleTap = (pageX, pageY) -> localField.rotateClockwise()

  dispatchTouchEvent = (allowTap) ->
    #logStatus "dispatching #{touchData.time1.getTime()}"
    deltaX = touchData.pageX2 - touchData.pageX0
    deltaY = touchData.pageY2 - touchData.pageY0
    slope = deltaY / deltaX
    absSlope = Math.abs(slope)
    xDist = Math.abs(deltaX)
    yDist = Math.abs(deltaY)
    lastDuration = Math.abs(touchData.time2.getTime() - touchData.time1.getTime())
    duration = Math.abs(touchData.time2.getTime() - touchData.time0.getTime())
    if xDist > 20 && absSlope < 0.5
      e = {
        distance: xDist
        duration: duration
        speed: xDist / lastDuration
        totalDeltaX: touchData.pageX2 - touchData.pageX0
      }
      handleHorizontalSwipe(e)
    else if yDist > 20 && absSlope > 2 && deltaY > 0
      handleSwipeDown({ distance: yDist, duration: duration, speed: yDist / lastDuration })
    else if allowTap && ! touchData.hasMoved && xDist < 10 && yDist < 10 && duration < 300
      handleTap(touchData.pageX2, touchData.pageY2)

  $(localFieldView.fieldSelector()).bind 'touchstart', (event) ->
    event.preventDefault()
    # Save initial state when user starts touching.
    touchData = {
      time0: new Date()
      pageX0: event.originalEvent.touches[0].pageX
      pageY0: event.originalEvent.touches[0].pageY
      hasMoved: false
      piece: localField.curFloating
      pieceInitX: currentPieceX()
      pieceInitY: currentPieceY()
    }
    touchData.time2 = touchData.time1 = touchData.time0
    touchData.pageX2 = touchData.pageX1 = touchData.pageX0
    touchData.pageY2 = touchData.pageY1 = touchData.pageY0

  $(localFieldView.fieldSelector()).bind 'touchmove', (event) ->
    return unless touchData
    event.preventDefault()
    # Update state of touch.
    touchData.hasMoved = true
    touchData.time1 = touchData.time2
    touchData.pageX1 = touchData.pageX2
    touchData.pageY1 = touchData.pageY2
    touchData.time2 = new Date()
    touchData.pageX2 = event.originalEvent.touches[0].pageX
    touchData.pageY2 = event.originalEvent.touches[0].pageY
    # React to touch movement.
    dispatchTouchEvent(false)

  $(localFieldView.fieldSelector()).bind 'touchend', (event) ->
    return unless touchData
    # This prevents double-tap zoom.
    event.preventDefault()
    # React since this may have been the end of a tap.
    dispatchTouchEvent(true)
    touchData = null

  $(localFieldView.fieldSelector()).bind 'touchcancel', (event) ->
    touchData = null

  # Play background music if present.
  music = $('#music').get(0)
  # music?.play()

  appendLine = (line, callback = null) ->
    $line = $('<div></div>')
    $line.appendTo('#status')
    k = (chars) ->
      if chars.length > 0
        $line.append(chars[0])
        _.delay (-> k(chars.substr(1))), 50
      else
        callback?()
    if line == ''
      $line.append('&nbsp;')
      _.delay (-> k('')), 50
    else
      k(line)

  appendMessage = (msg, callback = null) ->
    k = (lines) ->
      if lines.length > 0
        line = lines.shift()
        appendLine line, -> _.delay((-> k(lines)), 200)
      else
        callback?()
    k(msg.split(/\n/))

  # Set the status.
  $('#status').html('')
  appendMessage """
    Player, defragment this sector...
    Arrow Keys = move
    D = rotate left
    F = rotate right
    C = hard drop

  """, =>
    _.delay((=>
      # Start the game.
      appendLine 'Execute', =>
        game.start()
    ), 2000)

  # Listen for messages.
  game.receiveMessage = (playerName, msg) ->
    appendLine "#{playerName}: #{msg}"

  # Give us easy access from the console.
  window.game = game
  window.localField = localField
  window.localFieldView = localFieldView

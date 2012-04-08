require ['jquery', 'tetromino-engine', 'tetromino-dom-view', 'tetromino-push-to-server-view', 'decouple', 'underscore', 'now'], ($, TetrominoEngine, DomView, PushToServerView, decouple, _, now) ->

  now ?= window.now
  game = null
  localField = null
  localFieldView = null
  pushToServerView = null
  fieldViews = []

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
      pushToServerView = new PushToServerView.PlayingFieldView(game, field, now)

  fieldViewsFromPlayer = (player) ->
    fieldView for fieldView in fieldViews when fieldView.fieldModel == player.field

  game = new TetrominoEngine.TetrominoGame(now)
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

  # Touch interface.
  xyFromPageXy = (pageX, pageY) ->
    offset = $(localFieldView.fieldSelector()).offset()
    x = Math.floor((pageX - offset.left - localFieldView.borderWidth) / localFieldView.blockWidth)
    y = Math.floor((pageY - offset.top - localFieldView.borderHeight) / localFieldView.blockHeight)
    [x, y]

  handleTouch = (event) ->
    event.preventDefault()
    x = event.originalEvent.touches[0].pageX
    y = event.originalEvent.touches[0].pageY
    localField.moveTo(xyFromPageXy(x, y)...)

  $(localFieldView.fieldSelector()).bind 'touchstart', handleTouch
  $(localFieldView.fieldSelector()).bind 'touchmove', _.throttle(handleTouch, 50)

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

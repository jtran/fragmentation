require ['jquery', 'tetromino-engine', 'tetromino-dom-view', 'tetromino-push-to-server-view', 'decouple', 'now'], ($, TetrominoEngine, DomView, PushToServerView, decouple, now) ->

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


  localField.showNewFloatingBlock()

  $(document).bind 'keydown', (event) ->
    # console.log('keydown', event.which, String.fromCharCode(event.which))
    localField.moveLeft()  if (event.which == 37) # left arrow
    localField.moveRight() if (event.which == 39) # right arrow
    localField.fall()      if (event.which == 40) # down arrow
    localField.drop()      if (event.which == 191) # slash
    letter = String.fromCharCode(event.which).toLowerCase()
    localField.curFloating.rotateClockwise()        if (letter == 'f')
    localField.curFloating.rotateCounterclockwise() if (letter == 'd')
    localField.drop() if (letter == 'c')

  # Play background music if present.
  music = $('#music').get(0)
  # music?.play()

  game.start()

  # Give us easy access from the console.
  window.game = game
  window.localField = localField
  window.localFieldView = localFieldView

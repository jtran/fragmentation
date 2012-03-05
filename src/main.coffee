require ['jquery', 'tetromino-engine', 'tetromino-dom-view', 'tetromino-push-to-server-view', 'decouple', 'now'], ($, TetrominoEngine, DomView, PushToServerView, decouple, now) ->

  now ?= window.now
  game = null
  localField = null
  localFieldView = null
  pushToServerView = null
  fieldViews = []

  decouple.on null, 'new PlayingField', (field, event) ->
    console.log("adding DOM view #{fieldViews.length}", event, field)
    if field.viewType == 'local'
      fieldView = new DomView.PlayingFieldDomView(field, { ordinal: fieldViews.length })
      fieldViews.push(fieldView)
      # Keep a reference to the local view.
      localFieldView = fieldView
      # Create a push-to-server view on the local playing field.
      pushToServerView = new PushToServerView.PlayingFieldView(field, now)

  game = new TetrominoEngine.TetrominoGame(now)
  localField = game.localField

  localField.showNewFloatingBlock()

  $(document).bind 'mousedown', (event) -> localFieldView.rotateTheme()
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
  window.fieldViews = fieldViews

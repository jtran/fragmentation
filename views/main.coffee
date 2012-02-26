require ['jquery', 'tetromino-engine', 'tetromino-dom-view'], ($, TetrominoEngine, DomView) ->

  game = new TetrominoEngine.TetrominoGame()
  localField = game.localField

  localFieldView = new DomView.PlayingFieldDomView(localField)

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
  window.game = game;
  window.localField = localField;

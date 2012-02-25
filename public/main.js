require(['jquery', 'tetromino-engine'], function($, TetrominoEngine) {
  var game;
  var localField;

  game = new TetrominoEngine.TetrominoGame();
  localField = game.localField;

  localField.showNewFloatingBlock();

  $(document).bind('mousedown', function(event) { localField.rotateTheme(); });
  $(document).bind('keydown', function(event) {
//    console.log('keydown', event.which, String.fromCharCode(event.which));
    if (event.which == 37)  localField.moveLeft();
    if (event.which == 39)  localField.moveRight();
    if (event.which == 40)  localField.fall();
    if (event.which == 191) localField.drop(); // slash
    var letter = String.fromCharCode(event.which).toLowerCase();
    if (letter == 'f') localField.curFloating.rotateClockwise();
    if (letter == 'd') localField.curFloating.rotateCounterclockwise();
    if (letter == 'c') localField.drop();
  });

  // Play background music if present.
  var music = $('#music').get(0);
//  if (music) music.play();

  game.start();

  // Give us easy access from the console.
  window.game = game;
  window.localField = localField;
});

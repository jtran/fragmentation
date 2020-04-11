/**
 * Module dependencies.
 */
import express from 'express';
import errorhandler from 'errorhandler';

let app = express();

export default app;

// Configuration

const port = process.env.PORT || 3001;
app.set('port', port);
(function() {
  var publicDir = './public';
  var libDir = './lib';
  app.use(express.static(publicDir));
  app.use(express.static('./vendor/javascripts'));
  app.use(express.static(libDir));
})();

// Error handling should be last, after all routes.
if (app.get('env') === 'development') {
  app.use(errorhandler());
}

import http from 'http';
let httpServer = http.createServer(app);
httpServer.listen(port, function() {
  console.log("Express server listening on port %d in %s mode", httpServer.address().port, app.get('env'));
});


import tetrominoServer from './tetromino-server.js';
// Start the game server.
tetrominoServer.initializeGame(httpServer);

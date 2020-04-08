
/**
 * Module dependencies.
 */

var requirejs = require('requirejs');
requirejs.config({
  baseUrl: __dirname + '/lib',
  paths: {
    'require': 'vendor/javascripts/require'
  , 'underscore': 'vendor/javascripts/underscore'
  , 'tetromino-server': __dirname + '/tetromino-server'
  },
  //Pass the top-level main.js/index.js require
  //function to requirejs so that node modules
  //are loaded relative to the top-level JS file.
  nodeRequire: require
});

var express = require('express');
let errorhandler = require('errorhandler');

let app = module.exports = express();

// Configuration

const port = process.env.PORT || 3001;
app.set('port', port);
(function() {
  var publicDir = __dirname + '/public';
  var viewsDir = __dirname + '/views';
  var libDir = __dirname + '/lib';
  app.set('views', viewsDir);
  app.set('view engine', 'jade');
  app.use(express.static(publicDir));
  app.use(express.static(libDir));
  app.use(express.static(__dirname + '/vendor/javascripts'));
})();

// Error handling should be last, after all routes.
if (app.get('env') === 'development') {
  app.use(errorhandler());
}

let http = require('http');
let httpServer = http.createServer(app);
httpServer.listen(port, function() {
  console.log("Express server listening on port %d in %s mode", httpServer.address().port, app.get('env'));
});


// Must define this as a module so that we have access to it inside
// the requirejs call below.
requirejs.define('httpServer', function() {
  return httpServer;
});

// Our util module currently depends on jQuery, even though we never
// call those functions on the server.
requirejs.define('jquery', function() {
  return function() { throw("You tried to use jQuery on the server."); };
});

// Compile everything to JavaScript since requirejs can't handle
// CoffeeScript.  There's a plugin, but it means you have to know
// whether a module is implemented with JS or Coffee.  Screw that.
var exec = require('child_process').exec;
exec('cake build', function(err, stdout, stderr) {
  if (err) throw(err);
  console.log(stdout + stderr);
  requirejs(['httpServer', 'tetromino-server'], function(httpServer, tetrominoServer) {
    // Start the game server.
    tetrominoServer.initializeGame(httpServer);
  });
});

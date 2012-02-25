
/**
 * Module dependencies.
 */

var requirejs = require('requirejs');
requirejs.config({
    //Pass the top-level main.js/index.js require
    //function to requirejs so that node modules
    //are loaded relative to the top-level JS file.
    nodeRequire: require
});

var express = require('express');

var app = module.exports = express.createServer();

// Configuration

app.configure(function(){
  var publicDir = __dirname + '/public';
  var viewsDir = __dirname + '/views';
  app.set('views', viewsDir);
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.compiler({
    src: viewsDir,
    dest: publicDir,
    enable: ['coffeescript']
  }));
  app.use(express.static(publicDir));
});

app.configure('development', function(){
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true })); 
});

app.configure('production', function(){
  app.use(express.errorHandler()); 
});

// Routes

var port = process.env.PORT || 3001;
app.listen(port);
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);


requirejs.define('jquery', [], function() {
  return function() {
    console.error("You tried to use jQuery on the server side.");
  };
});

requirejs.define('jqueryui', [], function() {
  return function() {
    console.error("You tried to use jQueryUI on the server side.");
  };
});

requirejs(['./public/tetromino-engine'], function(engine) {
  console.log(engine);
});

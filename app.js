
/**
 * Module dependencies.
 */

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

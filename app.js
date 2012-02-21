
/**
 * Module dependencies.
 */

var express = require('express');
var nowjs = require('now');

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

var everyone = nowjs.initialize(app);

players = [];

nowjs.on("connect", function(){
  console.log("Connected clientId:" + this.user.clientId);
});

nowjs.on("disconnect", function(){
  console.log("Disconnected clientId:" + this.user.clientId + ", name:" + this.now.name);
  for (var i = 0; i < players.length; i++) {
    if (players[i].id == this.user.clientId) {
      for (var j = i + 1; j < players.length; j++) players[j - 1] = players[j];
      players.pop();
      break;
    }
  }
  console.log("players", players);
  everyone.now.players = players;
  everyone.now.removePlayer(this.user.clientId);
});


everyone.now.getPlayers = function(callback) { callback(players); };

everyone.now.distributeMessage = function(msg) {
  everyone.now.receiveMessage(this.user.clientId, this.now.name, msg);
};

everyone.now.joinGame = function(player) {
  player.id = this.user.clientId;
  players.push(player);
  console.log("players", players);
  everyone.now.players = players;
  everyone.now.addPlayer(player);
};

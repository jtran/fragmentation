define ['tetromino-engine', 'tetromino-player', 'now', 'underscore'], (engine, tetrominoPlayer, now, _) ->

  class TetrominoServer
    initializeGame: (@app) ->
      console.log 'init Game'
      server = @
      @models = models = new engine.ModelEventReceiver({ comment: 'dummy game' })
      @everyone = everyone = now.initialize(@app,
        { socketio: { transports: ['xhr-polling', 'jsonp-polling'], 'polling duration': 10 }})
      now.on 'connect', -> console.log("Connected #{@user.clientId}")
      now.on 'disconnect', ->
        id = @user.clientId
        console.log("Disconnected #{id}")
        models.removePlayer(id)
        everyone.now.removePlayer(id)
      everyone.now.getPlayers = (callback) ->
        ps = {}
        for k, p of models.players
          ps[k] = p.asJson()
        callback(ps)
      everyone.now.join = (fieldHash) ->
        id = @user.clientId
        console.log("Joined #{id}", fieldHash)
        player = new tetrominoPlayer.Player(id, fieldHash)
        models.addPlayer(player)
        everyone.now.addPlayer(player)
      everyone.now.distributeMessage = (msg) ->
        everyone.now.receiveMessage(@now.name ? @user.clientId, msg)
      everyone.now.distributeBlockEvent = (blockId, event, args...) ->
        models.receiveBlockEvent(@user.clientId, blockId, event, args...)
        everyone.now.receiveBlockEvent(@user.clientId, blockId, event, args...)
      everyone.now.distributeFieldEvent = (event, args...) ->
        models.receiveFieldEvent(@user.clientId, event, args...)
        everyone.now.receiveFieldEvent(@user.clientId, event, args...)
      everyone.now.distributeUpdatePlayingField = (fieldHash) ->
        # Client is sending us an update to his/her playing field.
        id = @user.clientId
        models.receiveUpdatePlayingField(id, fieldHash)
        # We do not broadcast the update.


  # Export singleton.
  root = exports ? this
  root.tetrominoServer = new TetrominoServer()

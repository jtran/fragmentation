define ['tetromino-engine', 'tetromino-event-model-mirror', 'tetromino-player', 'now', 'underscore'], (engine, modelMirror, tetrominoPlayer, now, _) ->

  class TetrominoServer
    initializeGame: (@app) ->
      console.log 'init Game'
      server = @
      @players = players = {}
      @eventModelMirror = eventModelMirror = new modelMirror.Mirror(@players, engine.FloatingBlock)
      @everyone = everyone = now.initialize(@app)
      now.on 'connect', -> console.log("Connected #{@user.clientId}")
      now.on 'disconnect', ->
        id = @user.clientId
        console.log("Disconnected #{id}")
        delete players[id]
        everyone.now.removePlayer(id)
      everyone.now.getPlayers = (callback) ->
        ps = _.clone(players)
        for k, p of players
          ps[k] = p.asJson()
        callback(ps)
      everyone.now.join = (fieldHash) ->
        id = @user.clientId
        console.log("Joined #{id}", fieldHash)
        player = new tetrominoPlayer.Player(id, engine.PlayingField.fromJson(id, { comment: 'dummy game' }, fieldHash))
        players[id] = player
        everyone.now.addPlayer(player.asJson())
      everyone.now.distributeMessage = (msg) ->
        everyone.now.receiveMessage(@user.clientId, msg)
      everyone.now.distributeBlockEvent = (blockId, event, args...) ->
        eventModelMirror.receiveBlockEvent(@user.clientId, blockId, event, args...)
        everyone.now.receiveBlockEvent(@user.clientId, blockId, event, args...)
      everyone.now.distributeFieldEvent = (event, args...) ->
        console.log 'fieldEvent', @user.clientId, event, args...
        eventModelMirror.receiveFieldEvent(@user.clientId, event, args...)
        everyone.now.receiveFieldEvent(@user.clientId, event, args...)
      everyone.now.updatePlayingField = (fieldHash) ->
        # Client is sending us an update to his/her playing field.
        id = @user.clientId
        unless players[id]
          console.warn "I got an updateClient for an unknown player id=#{id}"
          return
        console.log("Update playing field #{id}", fieldHash)
        # Store the updated field.
        players[id].field = engine.PlayingField.fromJson(id, { comment: 'dummy game' }, fieldHash)
        # We do not broadcast the update.  This is only used when a
        # new player joins and needs to initialize a full view of a
        # remote player's game.
        ## Broadcast the update to all players.
        ##everyone.now.updateRemotePlayingField(id, field)


  # Export singleton.
  root = exports ? this
  root.tetrominoServer = new TetrominoServer()

define ['tetromino-engine', 'now'], (engine, now) ->

  class TetrominoServer
    initializeGame: (@app) ->
      console.log 'init Game'
      @players = players = {}
      @everyone = everyone = now.initialize(@app)
      now.on 'connect', -> console.log("Connected #{@user.clientId}")
      now.on 'disconnect', ->
        id = @user.clientId
        console.log("Disconnected #{id}")
        delete players[id]
        everyone.now.removePlayer(id)
      everyone.now.getPlayers = (callback) => callback(@players)
      everyone.now.join = (field) ->
        id = @user.clientId
        console.log("Joined #{id}", field)
        player = {
          id: id
          field: field
        }
        players[id] = player
        everyone.now.addPlayer(player)
      everyone.now.distributeMessage = (msg) ->
        everyone.now.receiveMessage(@user.clientId, msg)
      everyone.now.updatePlayingField = (field) ->
        # Client is sending us an update to his/her playing field.
        id = @user.clientId
        unless players[id]
          console.warn "I got an updateClient for an unknown player id=#{id}"
          return
        console.log("Update playing field #{id}", field)
        # Store the updated field.
        players[id].field = field
        # Broadcast the update to all players.
        everyone.now.updateRemotePlayingField(id, field)


  # Export singleton.
  root = exports ? this
  root.tetrominoServer = new TetrominoServer()

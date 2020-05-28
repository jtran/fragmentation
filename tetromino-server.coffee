import engine from './lib/tetromino-engine.js'
import { Player } from './lib/tetromino-player.js'
import socketio from 'socket.io'
import _ from 'underscore'

class TetrominoServer
  initializeGame: (@httpServer) ->
    console.log 'init Game'
    server = @
    @models = models = new engine.ModelEventReceiver({ comment: 'dummy game' })
    io = socketio(@httpServer, cookie: false)
    io.on 'connection', (socket) ->
      console.log("Connected #{socket.id}")
      # This is so we know the playerId when it disconnects without warning.
      connectionPlayer = { id: null }
      socket.on 'disconnect', ->
        console.log("Disconnected #{connectionPlayer.id} #{socket.id}")
        models.removePlayer(connectionPlayer.id, socket.id)
        socket.broadcast.emit('removePlayer', connectionPlayer.id, socket.id)
      socket.on 'getPlayers', (callback) ->
        ps = {}
        for k, p of models.players
          ps[k] = p.asJson()
        callback(ps)
      socket.on 'join', (playerHash) ->
        console.log("Joined #{playerHash.id} #{socket.id}", playerHash)
        connectionPlayer.id = playerHash.id
        models.addPlayer(playerHash)
        socket.broadcast.emit('addPlayer', playerHash)
      socket.on 'distributeMessage', (playerId, msg) ->
        socket.broadcast.emit('receiveMessage', playerId, msg)
      socket.on 'distributeBlockEvent', (playerId, blockId, event, args...) ->
        models.receiveBlockEvent(playerId, blockId, event, args...)
        socket.broadcast.emit('receiveBlockEvent', playerId, blockId, event, args...)
      socket.on 'distributeFieldEvent', (playerId, event, args...) ->
        models.receiveFieldEvent(playerId, event, args...)
        socket.broadcast.emit('receiveFieldEvent', playerId, event, args...)

export default new TetrominoServer()

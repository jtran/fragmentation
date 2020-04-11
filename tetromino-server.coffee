`import engine from './lib/tetromino-engine.js'`
`import tetrominoPlayer from './lib/tetromino-player.js'`
`import socketio from 'socket.io'`
`import _ from 'underscore'`

class TetrominoServer
  initializeGame: (@httpServer) ->
    console.log 'init Game'
    server = @
    @models = models = new engine.ModelEventReceiver({ comment: 'dummy game' })
    io = socketio(@httpServer)
    io.on 'connection', (socket) ->
      console.log("Connected #{socket.id}")
      socket.on 'disconnect', ->
        id = socket.id
        console.log("Disconnected #{id}")
        models.removePlayer(id)
        socket.broadcast.emit('removePlayer', id)
      socket.on 'getPlayers', (callback) ->
        ps = {}
        for k, p of models.players
          ps[k] = p.asJson()
        callback(ps)
      socket.on 'join', (fieldHash) ->
        id = socket.id
        console.log("Joined #{id}", fieldHash)
        player = new tetrominoPlayer.Player(id, fieldHash)
        models.addPlayer(player)
        socket.broadcast.emit('addPlayer', player)
      socket.on 'distributeMessage', (msg) ->
        socket.broadcast.emit('receiveMessage', socket.id, msg)
      socket.on 'distributeBlockEvent', (blockId, event, args...) ->
        models.receiveBlockEvent(socket.id, blockId, event, args...)
        socket.broadcast.emit('receiveBlockEvent', socket.id, blockId, event, args...)
      socket.on 'distributeFieldEvent', (event, args...) ->
        models.receiveFieldEvent(socket.id, event, args...)
        socket.broadcast.emit('receiveFieldEvent', socket.id, event, args...)

`export default new TetrominoServer()`

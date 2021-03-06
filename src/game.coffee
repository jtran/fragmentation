import { ModelEventReceiver, PlayingField } from './tetromino-engine.js'
import { Player }  from './tetromino-player.js'

# A game on the client.
export class Game
  constructor: (@serverSocket, localPlayerId) ->
    @joinedRemoteGame = false
    @socketCallbacksDone = false
    @localField = null
    @localPlayer = null
    @models = new ModelEventReceiver(@, localPlayerId)
    @addLocalPlayer(localPlayerId)
    game = @
    # This gets called when the client connects to the server, and
    # again each time it reconnects.
    @serverSocket.on 'connect', =>
      console.log 'connected'
      @initSocketCallbacks()
      @localPlayer.socketId = @serverSocket.id
      @models.addPlayer(@localPlayer)
      @serverSocket.on 'receiveMessage', (playerName, msg) ->
        game.receiveMessage?(playerName, msg)
      @serverSocket.on 'addPlayer', @models.addPlayer
      @serverSocket.on 'removePlayer', @models.removePlayer
      @serverSocket.on 'receiveBlockEvent', @models.receiveBlockEvent
      @serverSocket.on 'receiveFieldEvent', @models.receiveFieldEvent
      @serverSocket.on 'receiveUpdatePlayingField', @models.receiveUpdatePlayingField
      @serverSocket.emit 'join', @localPlayer.asJson(), (players) =>
        console.log 'initial players on join', players
        @models.addPlayer(p) for id, p of players
        @joinedRemoteGame = true

  initSocketCallbacks: ->
    # Only do this once.
    return if @socketCallbacksDone
    @socketCallbacksDone = true
    @serverSocket.on 'disconnect', =>
      console.log 'disconnected'
      @joinedRemoteGame = false
      @localPlayer.socketId = null

  addLocalPlayer: (localPlayerId) ->
    throw new Error("You tried to add a local player, but I already have one.") if @localField
    @localField = new PlayingField(@, viewType: 'local')
    @localPlayer = new Player(localPlayerId, null, @localField)
    @localField.useNextPiece()
    @localPlayer

  start: -> @localField?.setUseGravity(true)

  playersMap: -> @models.players

  players: -> Array.from(@models.players.values())


export default {
  Game
}

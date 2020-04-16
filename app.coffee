import express from 'express'
import errorhandler from 'errorhandler'
import http from 'http'
import tetrominoServer from './tetromino-server.js'

app = express()
export default app

# Configuration
port = process.env.PORT || 3001
app.set('port', port)
app.use(express.static('./public'))
app.use(express.static('./vendor/javascripts'))
app.use(express.static('./lib'))

# Error handling should be last, after all routes.
if app.get('env') == 'development'
  app.use(errorhandler())

# Start serving files.
httpServer = http.createServer(app)
httpServer.listen port, ->
  console.log "Express server listening on port %d in %s mode", httpServer.address().port, app.get('env')

# Start the game server.
tetrominoServer.initializeGame(httpServer)

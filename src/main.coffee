#`import $ from './jquery-1.6.2.min.js'`
#`import _ from './underscore.js'`

import { Game } from './game.js'
import { PlayingField } from './tetromino-engine.js'
import { PlayingFieldDomView } from './tetromino-dom-view.js'
import { PlayingFieldView as PushToServerView } from './tetromino-push-to-server-view.js'
import decouple from './decouple.js'
import util from './util.js'
import version from './version.js'

socket = null
game = null
localField = null
localFieldView = null
pushToServerView = null
fieldViews = []

# For debugging.
logStatus = (msg) -> $('#status').prepend("<div>#{msg}</div>")

# Generate a UUIDv4.
#
# TODO: Move this to util.  The issue is that WebCrypto isn't implemented in
# node.  Node's crypto module has a different interface.
genUuid = () ->
  ([1e7]+-1e3+-4e3+-8e3+-1e11).replace /[018]/g, (c) ->
    (c ^ window.crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)

handleAddPlayer = (game, event, player) ->
  # This gets called after connecting to the server, but we don't wait for that
  # for the local player.  We run this proactively so that we have a view of our
  # local player before connecting completes.
  field = player.field
  return if field == localField && localFieldView?
  console.log("adding DOM view #{fieldViews.length}", event, field)
  options =
    ordinal: fieldViews.length
    themeIndex: if field.viewType == 'local' then 0 else 2
  fieldView = new PlayingFieldDomView(field, options)
  fieldViews.push(fieldView)
  if field.viewType == 'local'
    # Keep a reference to the local view.
    localFieldView = fieldView
    # Create a push-to-server view on the local playing field.
    pushToServerView = new PushToServerView(game, field, socket)

# Setup debug mode.
urlParams = new URLSearchParams(window.location.search)
decouple.on null, 'newPlayingFieldBeforeInit', (game, event, field) =>
  field.DEBUG = urlParams.get('debug')
  field.pieceGenerator.DEBUG = urlParams.get('debug')

socket = io()
game = new Game(socket, genUuid())
localField = game.localField
# Handle the local player to create a view of the local field.
handleAddPlayer(game, 'addPlayer', game.localPlayer)
# Listen for other players.
decouple.on game, 'addPlayer', handleAddPlayer

fieldViewsFromPlayer = (player) ->
  fieldView for fieldView in fieldViews when fieldView.fieldModel == player.field

# Re-organize the view when a player leaves the game.
decouple.on game, 'afterRemovePlayer', (caller, event, player) =>
  for fieldView in fieldViewsFromPlayer(player)
    fieldView.leaveGame? =>
      # Remove from the field views collection.
      fieldViews = util.without(fieldViews, fieldView)
      # Set ordinals of remaining views.
      i = 0
      for fv in _.sortBy fieldViews, (fv) -> fv.getOrdinal()
        fv.setOrdinal(i)
        i++

decouple.on localField, 'stateChange', (caller, event, newState) =>
  switch newState
    when PlayingField.STATE_GAMEOVER then music?.pause()

$(document).bind 'keydown', (event) ->
  # console.log('keydown', event.which, String.fromCharCode(event.which))
  handled = switch event.which
    when 37  ### left arrow  ### then localField.onInput(action: 'left'); true
    when 39  ### right arrow ### then localField.onInput(action: 'right'); true
    when 40  ### down arrow  ### then localField.onInput(action: 'down'); true
    when 38  ### up arrow    ### then localField.onInput(action: 'up'); true
    when 191 ### slash       ### then localField.onInput(action: 'slash'); true
    when 27  ### escape      ### then localField.onInput(action: 'escape'); true
  handled or= switch String.fromCharCode(event.which).toLowerCase()
    when 'f'                     then localField.onInput(action: 'f'); true
    when 'd'                     then localField.onInput(action: 'd'); true
    when ' ' ### spacebar    ### then localField.onInput(action: 'spacebar'); true
    when 'm'                     then toggleMusic(); true
  event.preventDefault() if handled

##############################
# Touch interface.

touchData = null

currentPieceX = -> localField.curFloating.blocks[localField.curFloating.centerIndex].x
currentPieceY = -> localField.curFloating.blocks[localField.curFloating.centerIndex].y

handleHorizontalSwipe = (e) ->
  x0 = touchData.pieceInitX
  x1 = currentPieceX()
  distDiff = Math.floor(e.totalDeltaX / 20)
  #logStatus "#{e.distance} #{e.totalDeltaX} #{distDiff} #{x0} #{x1}"
  localField.onInput(action: 'swipeHorizontal', x: x0 + distDiff)

handleSwipeDown = (e) ->
  #logStatus "begin down #{e.distance} #{e.distance}"
  y0 = touchData.pieceInitY
  y1 = currentPieceY()
  distDiff = Math.floor(e.distance / 20)
  yDiff = (y0 + distDiff) - y1
  #logStatus "#{e.distance} #{e.distance} #{distDiff} #{y0} #{y1}"
  if localField.curFloating == touchData.piece
    localField.onInput(action: 'swipeDown', yDiff: yDiff)

handleTap = (pageX, pageY) -> localField.onInput(action: 'tap')

dispatchTouchEvent = (allowTap) ->
  #logStatus "dispatching #{touchData.time1.getTime()}"
  deltaX = touchData.pageX2 - touchData.pageX0
  deltaY = touchData.pageY2 - touchData.pageY0
  slope = deltaY / deltaX
  absSlope = Math.abs(slope)
  xDist = Math.abs(deltaX)
  yDist = Math.abs(deltaY)
  lastDuration = Math.abs(touchData.time2.getTime() - touchData.time1.getTime())
  duration = Math.abs(touchData.time2.getTime() - touchData.time0.getTime())
  if xDist > 20 && absSlope < 0.5
    e = {
      distance: xDist
      duration: duration
      speed: xDist / lastDuration
      totalDeltaX: touchData.pageX2 - touchData.pageX0
    }
    handleHorizontalSwipe(e)
  else if yDist > 20 && absSlope > 2 && deltaY > 0
    handleSwipeDown({ distance: yDist, duration: duration, speed: yDist / lastDuration })
  else if allowTap && xDist < 10 && yDist < 10 && duration < 300
    handleTap(touchData.pageX2, touchData.pageY2)

getEventData = (event) ->
  if event.type.includes('pointer')
    return event.originalEvent
  else
    return event.originalEvent.touches[0]

startHandler = (event) ->
  event.preventDefault()
  eventData = getEventData(event)
  # Save initial state when user starts touching.
  touchData = {
    time0: new Date()
    pageX0: eventData.pageX
    pageY0: eventData.pageY
    piece: localField.curFloating
    pieceInitX: currentPieceX()
    pieceInitY: currentPieceY()
  }
  touchData.time2 = touchData.time1 = touchData.time0
  touchData.pageX2 = touchData.pageX1 = touchData.pageX0
  touchData.pageY2 = touchData.pageY1 = touchData.pageY0

moveHandler = (event) ->
  return unless touchData
  event.preventDefault()
  eventData = getEventData(event)
  # Update state of touch.
  touchData.time1 = touchData.time2
  touchData.pageX1 = touchData.pageX2
  touchData.pageY1 = touchData.pageY2
  touchData.time2 = new Date()
  touchData.pageX2 = eventData.pageX
  touchData.pageY2 = eventData.pageY
  # React to touch movement.
  if (event.originalEvent.pointerType != 'mouse')
    dispatchTouchEvent(false)

endHandler = (event) ->
  return unless touchData
  # This prevents double-tap zoom.
  event.preventDefault()
  eventData = getEventData(event)
  # React since this may have been the end of a tap.
  if (event.originalEvent.pointerType != 'mouse')
    dispatchTouchEvent(true)
  touchData = null

cancelHandler = (event) ->
  touchData = null

$(localFieldView.fieldSelector()).bind 'pointerdown', startHandler
$(localFieldView.fieldSelector()).bind 'pointerup', endHandler
$(localFieldView.fieldSelector()).bind 'pointermove', moveHandler
$(localFieldView.fieldSelector()).bind 'pointerout', cancelHandler

ignore = (evt) ->
  evt.preventDefault()
  false
$(localFieldView.fieldSelector()).bind 'touchstart', ignore
$(localFieldView.fieldSelector()).bind 'touchend', ignore
$(localFieldView.fieldSelector()).bind 'touchmove', ignore
$(localFieldView.fieldSelector()).bind 'touchcancel', ignore

##############################
# Beginning of game sequence.

music = $('#music').get(0)

playMusic = ->
  return unless music?
  music.play() if music.paused

toggleMusic = ->
  return unless music?
  if music.paused
    music.play()
  else
    music.pause()

# Play background music if present and autoplay is set.
do ->
  return unless music?
  # Load settings.
  musicVolumeStr = window.localStorage.musicVolume ? ''
  if musicVolumeStr.length > 0
    music.volume = parseFloat(musicVolumeStr)
  if window.localStorage.autoplayMusic in ['1', 'true']
    playMusic()

appendLine = (line, callback = null) ->
  $line = $('<div></div>')
  $line.appendTo('#status')
  k = (chars) ->
    if chars.length > 0
      $line.append(chars[0])
      _.delay (-> k(chars.substr(1))), 50
    else
      callback?($line)
  if line == ''
    $line.append('&nbsp;')
    _.delay (-> k('')), 50
  else
    k(line)

appendMessage = (msg, callback = null) ->
  k = (lines) ->
    if lines.length > 0
      line = lines.shift()
      appendLine line, -> _.delay((-> k(lines)), 200)
    else
      callback?()
  k(msg.split(/\n/))

# Set the status.
appendMessage """
  Player, defragment this sector...
  Arrow Keys = move
  D = rotate left
  F = rotate right
  Spacebar = hard drop

""", =>
  _.delay((=>
    # Hide the welcome.
    $('#welcome').removeClass('visible')

    # Start the game.
    appendLine 'Execute', =>
      game.start()
  ), 2000)

appendLine version, ($versionLine) =>
  _.delay((=> $versionLine.addClass('hide_text') ), 1000);

# Listen for messages.
game.receiveMessage = (playerName, msg) ->
  appendLine "#{playerName}: #{msg}"

# Give us easy access from the console.
window.game = game
window.localField = localField
window.localFieldView = localFieldView

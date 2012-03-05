define ['underscore', 'decouple', 'now'], (_, decouple, now) ->

  # View of a PlayingField model that pushes updates to the server.
  class PlayingFieldView
    constructor: (@fieldModel, @now) ->
      decouple.on @fieldModel, 'clear',          (args...) => @push()
      decouple.on @fieldModel, 'afterLandPiece', (args...) => @push()

    push: -> @now.updatePlayingField @fieldModel.asJson()


  # Exports
  root = exports ? this
  root.TetrominoPushToServerView =
    PlayingFieldView: PlayingFieldView

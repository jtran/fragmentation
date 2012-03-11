define [], ->

  class Player
    constructor: (@id, @field) ->

    asJson: -> { id: @id, field: @field.asJson() }


  # Exports
  root = exports ? this
  root.TetrominoPlayer =
    Player: Player

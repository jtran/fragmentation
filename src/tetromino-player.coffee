do ->
  class Player
    constructor: (@id, @field) ->

    asJson: -> { id: @id, field: @field.asJson() }


  export default
    Player: Player

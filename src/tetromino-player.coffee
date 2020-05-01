export class Player
  constructor: (@id, @socketId, @field) ->

  asJson: -> { id: @id, field: @field.asJson() }

export default { Player }

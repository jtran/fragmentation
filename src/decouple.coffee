# De-coupling with events.
class Decouple
  constructor: ->
    @bindings = []
    @modifiers = []

  on: (caller, event, callback) ->
    @bindings.push({ caller: caller, event: event, callback: callback })
    callback

  modify: (caller, event, operator = _.identity ) ->
    @modifiers.push({ caller, event, operator })
    operator

  removeAllForCaller: (caller) ->
    @bindings = (b for b in @bindings when b.caller != caller)
    @modifiers = (m for m in @modifiers when m.caller != caller)

  trigger: (caller, event, args...) ->
    throw new Error("You tried to trigger #{event} with undefined caller") if typeof caller == 'undefined'
    for b in @bindings when b.event == event and (not b.caller or b.caller == caller)
      for m in @modifiers when m.event == event and (not b.caller or m.caller == b.caller)
        args = m.operator args
      b.callback(caller, event, args...)
    null




export default new Decouple()

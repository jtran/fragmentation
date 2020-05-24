# De-coupling with events.
class Decouple
  constructor: ->
    @bindings = []

  on: (caller, event, callback) ->
    @bindings.push({ caller: caller, event: event, callback: callback })
    callback

  removeAllForCaller: (caller) ->
    @bindings = (b for b in @bindings when b.caller != caller)

  trigger: (caller, event, args...) ->
    throw new Error("You tried to trigger #{event} with undefined caller") if typeof caller == 'undefined'
    for b in @bindings when b.event == event and (not b.caller or b.caller == caller)
      b.callback(caller, event, args...)
    null


export default new Decouple()

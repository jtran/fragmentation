# De-coupling with events.
class Decouple
  constructor: ->
    @reset()

  reset: ->
    @bindings = []
    @modifiers = []

  # Caller is what's triggering the event.  Target is the handler object.
  on: (caller, event, target, callback) ->
    # `target` is optional.
    if not callback?
      callback = target
      target = null
    @bindings.push({ caller, event, target, callback })
    callback

  modify: (caller, event, target, operator = (x) -> x ) ->
    @modifiers.push({ caller, event, target, operator })
    operator

  removeAllForCaller: (caller) ->
    @bindings = (b for b in @bindings when b.caller != caller)
    @modifiers = (m for m in @modifiers when m.caller != caller)

  # Listeners can call this to remove themselves.
  removeAllForTarget: (target) ->
    @bindings = (b for b in @bindings when b.target != target)
    @modifiers = (m for m in @modifiers when m.target != target)

  trigger: (caller, event, args...) ->
    throw new Error("You tried to trigger #{event} with undefined caller") if typeof caller == 'undefined'
    for b in @bindings when b.event == event and (not b.caller or b.caller == caller)
      for m in @modifiers when m.event == event and (not b.caller or m.caller == b.caller)
        args = m.operator args
      b.callback(caller, event, args...)
    null


export default new Decouple()

# De-coupling with events.
define [], ->

  class Decouple
    constructor: ->
      @bindings = []

    on: (caller, event, callback) ->
      @bindings.push({ caller: caller, event: event, callback: callback })
      callback

    removeAllForCaller: (caller) ->
      @bindings = (b for b in @bindings when b.caller != caller)

    trigger: (caller, event, args...) ->
      for b in @bindings when b.event == event and (not b.caller or b.caller == caller)
        b.callback(caller, event, args...)
      null


  # Export singleton.
  root = exports ? this
  root.decouple = new Decouple()

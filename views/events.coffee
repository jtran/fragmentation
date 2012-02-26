# De-coupling with events.
define [], ->

  class Events
    constructor: ->
      @bindings = []

    listen: (caller, event, callback) ->
      @bindings.push({ caller: caller, event: event, callback: callback })
      callback

    trigger: (caller, event, args...) ->
      for b in @bindings when b.event == event and (not b.caller or b.caller == caller)
        b.callback(caller, event, args...)
      null


  # Export singleton.
  root = exports ? this
  root.events = new Events()

define ['jquery'], ($) ->

  # Return random integer in interval [0...n].
  randInt = (n) ->
    Math.floor(Math.random() * (n+1))

  setPosition = (sel, left, top) ->
    $(sel).css({'left': left + 'px', 'top': top + 'px'})

  # Exports
  root = exports ? this
  root.util =
    randInt: randInt
    setPosition: setPosition

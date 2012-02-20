# Exports
root = exports ? this

# Return random integer in interval [0...n].
root.randInt = (n) ->
  Math.floor(Math.random() * (n+1))

root.setPosition = (sel, left, top) ->
  $(sel).css({'left': left + 'px', 'top': top + 'px'})

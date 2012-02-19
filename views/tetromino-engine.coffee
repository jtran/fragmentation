# Represents a single square.
class Block
  constructor: (@x, @y) ->
    @elm = document.createElement('div')
    @elm.className = 'block next'
    @setXy([x, y])

  setXy: (xy) ->
    @x = xy[0]
    @y = xy[1]
    setElementXy(@elm, xy)

  getXy: -> [@x, @y]



class FloatingBlock
  constructor: ->
    @type = randInt(NUM_TYPES_OF_BLOCKS - 1)
    @canRotate = true
    @blocks = []
    mid = Math.floor(fieldWidth / 2) - 1
    switch @type
      when 0  # O
        @blocks.push(new Block(mid,     0))
        @blocks.push(new Block(mid + 1, 0))
        @blocks.push(new Block(mid,     1))
        @blocks.push(new Block(mid + 1, 1))
        @centerIndex = 0
        @canRotate = false
        $(@elms()).addClass('light')
      when 1  # T
        @blocks.push(new Block(mid - 1, 0))
        @blocks.push(new Block(mid,     0))
        @blocks.push(new Block(mid + 1, 0))
        @blocks.push(new Block(mid,     1))
        @centerIndex = 1
        $(@elms()).addClass('light')
      when 2  # S
        @blocks.push(new Block(mid + 1, 0))
        @blocks.push(new Block(mid,     0))
        @blocks.push(new Block(mid,     1))
        @blocks.push(new Block(mid - 1, 1))
        @centerIndex = 2
        $(@elms()).addClass('dark')
      when 3  # Z
        @blocks.push(new Block(mid - 1, 0))
        @blocks.push(new Block(mid,     0))
        @blocks.push(new Block(mid,     1))
        @blocks.push(new Block(mid + 1, 1))
        @centerIndex = 2
        $(@elms()).addClass('dark')
      when 4  # L
        @blocks.push(new Block(mid - 1, 0))
        @blocks.push(new Block(mid,     0))
        @blocks.push(new Block(mid + 1, 0))
        @blocks.push(new Block(mid - 1, 1))
        @centerIndex = 1
        $(@elms()).addClass('dark')
      when 5  # J
        @blocks.push(new Block(mid - 1, 0))
        @blocks.push(new Block(mid,     0))
        @blocks.push(new Block(mid + 1, 0))
        @blocks.push(new Block(mid + 1, 1))
        @centerIndex = 1
        $(@elms()).addClass('dark')
      when 6  # I
        @blocks.push(new Block(mid - 1, 0))
        @blocks.push(new Block(mid,     0))
        @blocks.push(new Block(mid + 1, 0))
        @blocks.push(new Block(mid + 2, 0))
        @centerIndex = 1
        $(@elms()).addClass('light')
      else
        throw "I don't know how to create a floating block of this type: " + @type

    # Use theme.
    $(@elms()).addClass(THEMES[themeIndex])


  elms: -> blk.elm for blk in @blocks

  # Takes a function that takes single argument the Block to be
  # transformed, which returns the Block's new xy.  Returns true if the
  # transformation was possible.
  transform: (f) ->
    xys2 = (f(blk) for blk in @blocks)
    return false if _(xys2).some(isXyTaken)
    _.each(@blocks, (blk, i) ->
      blk.setXy(xys2[i]))
    true

  rotateClockwise: ->
    return false unless @canRotate
    xyCenter = @blocks[@centerIndex].getXy()
    rotateWithShift = (shift) ->
      (blk) ->
        xy = blk.getXy()
        dx = xy[0] - xyCenter[0]
        dy = xy[1] - xyCenter[1]
        [xyCenter[0] - dy + shift, xyCenter[1] + dx]
    @transform(rotateWithShift(0)) ||
      @transform(rotateWithShift(1)) ||
      @transform(rotateWithShift(-1))

  rotateCounterclockwise: ->
    return false unless @canRotate
    xyCenter = @blocks[@centerIndex].getXy()
    rotateWithShift = (shift) ->
      (blk) ->
        xy = blk.getXy()
        dx = xy[0] - xyCenter[0]
        dy = xy[1] - xyCenter[1]
        [xyCenter[0] + dy + shift, xyCenter[1] - dx]
    @transform(rotateWithShift(0)) ||
      @transform(rotateWithShift(1)) ||
      @transform(rotateWithShift(-1))



# Exports
root = exports ? this
root.Block = Block
root.FloatingBlock = FloatingBlock

define ['underscore', 'util', 'jquery', 'jqueryui'], (_, util, $, jqueryui) ->

  # Represents a single square.
  class Block
    constructor: (@field, @x, @y) ->
      @elm = document.createElement('div')
      @elm.className = 'block next'
      @setXy([x, y])

    setXy: (xy) ->
      @x = xy[0]
      @y = xy[1]
      @field.setElementXy(@elm, xy)

    getXy: -> [@x, @y]


  # Convenience for chaining.
  xyOf = (blk) -> blk.getXy()


  class FloatingBlock
    NUM_TYPES_OF_BLOCKS = 7;

    constructor: (@field) ->
      @type = util.randInt(NUM_TYPES_OF_BLOCKS - 1)
      @canRotate = true
      @blocks = []
      mid = Math.floor(@field.fieldWidth / 2) - 1
      switch @type
        when 0  # O
          @blocks.push(new Block(@field, mid,     0))
          @blocks.push(new Block(@field, mid + 1, 0))
          @blocks.push(new Block(@field, mid,     1))
          @blocks.push(new Block(@field, mid + 1, 1))
          @centerIndex = 0
          @canRotate = false
          $(@elms()).addClass('light')
        when 1  # T
          @blocks.push(new Block(@field, mid - 1, 0))
          @blocks.push(new Block(@field, mid,     0))
          @blocks.push(new Block(@field, mid + 1, 0))
          @blocks.push(new Block(@field, mid,     1))
          @centerIndex = 1
          $(@elms()).addClass('light')
        when 2  # S
          @blocks.push(new Block(@field, mid + 1, 0))
          @blocks.push(new Block(@field, mid,     0))
          @blocks.push(new Block(@field, mid,     1))
          @blocks.push(new Block(@field, mid - 1, 1))
          @centerIndex = 2
          $(@elms()).addClass('dark')
        when 3  # Z
          @blocks.push(new Block(@field, mid - 1, 0))
          @blocks.push(new Block(@field, mid,     0))
          @blocks.push(new Block(@field, mid,     1))
          @blocks.push(new Block(@field, mid + 1, 1))
          @centerIndex = 2
          $(@elms()).addClass('dark')
        when 4  # L
          @blocks.push(new Block(@field, mid - 1, 0))
          @blocks.push(new Block(@field, mid,     0))
          @blocks.push(new Block(@field, mid + 1, 0))
          @blocks.push(new Block(@field, mid - 1, 1))
          @centerIndex = 1
          $(@elms()).addClass('dark')
        when 5  # J
          @blocks.push(new Block(@field, mid - 1, 0))
          @blocks.push(new Block(@field, mid,     0))
          @blocks.push(new Block(@field, mid + 1, 0))
          @blocks.push(new Block(@field, mid + 1, 1))
          @centerIndex = 1
          $(@elms()).addClass('dark')
        when 6  # I
          @blocks.push(new Block(@field, mid - 1, 0))
          @blocks.push(new Block(@field, mid,     0))
          @blocks.push(new Block(@field, mid + 1, 0))
          @blocks.push(new Block(@field, mid + 2, 0))
          @centerIndex = 1
          $(@elms()).addClass('light')
        else
          throw "I don't know how to create a floating block of this type: " + @type

      # Use theme.
      $(@elms()).addClass(@field.getTheme())


    elms: -> blk.elm for blk in @blocks

    # Takes a function that takes single argument the Block to be
    # transformed, which returns the Block's new xy.  Returns true if the
    # transformation was possible.
    transform: (f) ->
      xys2 = (f(blk) for blk in @blocks)
      return false if _(xys2).some(_.bind(@field.isXyTaken, @field))
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



  class PlayingField
    THEMES = ['blue', 'orange', 'yellow']

    constructor: (options) ->
      @ordinal = options.ordinal
      @fieldHeight = 22
      @fieldWidth = 10
      @blockHeight = 20
      @blockWidth = 20
      @borderWidth = 1
      @borderHeight = 1
      @blocks = []

      @themeIndex = 0

      @curFloating = null
      @nextFloating = null
      @fallTimer = null

      # Initialize blocks matrix.
      for i in [0 ... @fieldHeight]
        row = []
        row.push(null) for j in [0 ... @fieldWidth]
        @blocks.push(row)

      # Create elements on page.
      $('#background').append("""
        <div id="field_#{@ordinal}" class="field">
          <div class="field_background"></div>
          <div id="tail_#{@ordinal}" class="tail"></div>
        </div>
        """)

      # Use default theme.
      @setTheme(THEMES[@themeIndex]);


    fieldSelector: -> "#field_#{@ordinal}"
    tailSelector:  -> "#tail_#{@ordinal}"

    getTheme: -> THEMES[@themeIndex]


    setTheme: (theme) ->
      $('.block, .tail', @fieldSelector()).addClass(theme)


    rotateTheme: ->
      $('.block, .tail', @fieldSelector()).removeClass(THEMES[@themeIndex])
      @themeIndex = (@themeIndex + 1) % THEMES.length
      @setTheme(THEMES[@themeIndex])


    setElementXy: (sel, xy) ->
      util.setPosition(sel,
                       2 * @borderWidth  + xy[0] * @blockWidth,
                       2 * @borderHeight + xy[1] * @blockHeight)


    blockFromXy: (xy) ->
      row = xy[1]
      return null if row < 0 || row >= @blocks.length
      col = xy[0]
      return null if col < 0 || col >= @blocks[row].length
      @blocks[row][col]


    storeBlock: (blk, xy) -> @blocks[xy[1]][xy[0]] = blk


    isXyFree: (xy) ->
      @blockFromXy(xy) == null &&
        xy[0] >= 0 && xy[0] < @fieldWidth &&
        xy[1] >= 0 && xy[1] < @fieldHeight


    isXyTaken: (xy) -> ! @isXyFree(xy)


    moveLeft: ->
      @curFloating.transform((blk) ->
        xy = blk.getXy()
        [xy[0] - 1, xy[1]]
      )

    moveRight: ->
      @curFloating.transform((blk) ->
        xy = blk.getXy()
        [xy[0] + 1, xy[1]]
      )


    moveDown: ->
      @curFloating.transform((blk) ->
        xy = blk.getXy()
        [xy[0], xy[1] + 1]
      )


    landFloatingBlock: (flt) ->
      for blk in flt.blocks
        @storeBlock(blk, blk.getXy())
      null


    # Returns array of y's of lines that need to be cleared.
    linesToClear: (flt) ->
      linesToCheck = _(blk.getXy()[1] for blk in flt.blocks).uniq()
      y for y in linesToCheck when _(@blocks[y]).all(_.identity)


    fillLinesFromAbove: (ys) ->
      return if _.isEmpty(ys)
      shift = 1
      ys.sort()
      for y in [_.last(ys) .. 0]
        shift++ while _.include(ys, y - shift)
        for x in [0 ... @fieldWidth]
          blk = @blockFromXy([x, y - shift])
          blk?.setXy([x, y])
          @storeBlock(blk, [x, y])
      null


    clearLines: (ys) ->
      blksToRemove = []
      for y in ys
        for x in [0 ... @fieldWidth]
          blk = @blocks[y][x]
          @storeBlock(null, [x, y])
          continue unless blk
          $(blk.elm).css({'border-radius': '0', 'width': @blockWidth + 'px', 'left': (blk.x * @blockWidth + @borderWidth) + 'px'})
          blksToRemove.push(blk.elm)
      _.delay((-> $(blksToRemove).remove()), 500)
      null


    showNewFloatingBlock: ->
      # The first time this is called, next will be null.
      if ! @nextFloating
        @nextFloating = new FloatingBlock(this)
        $(@nextFloating.elms()).appendTo(@fieldSelector())

      # Make next be current and spawn a new next.
      @curFloating = @nextFloating
      @nextFloating = new FloatingBlock(this)
      # Move the new current into position.
      $(@curFloating.elms()).removeClass('next')
      blk.setXy([blk.x, blk.y + 2]) for blk in @curFloating.blocks
      $(@nextFloating.elms()).appendTo(@fieldSelector())
      null


    # Returns true if game is over.
    checkForGameOver: ->
      return false if _(blk.getXy() for blk in @curFloating.blocks).all(_.bind(@isXyFree, this))
      @stopGravity()

      music = $('#music').get(0)
      music.pause() if music

      true


    fall: ->
      fell = @moveDown()
      if ! fell
        @landFloatingBlock(@curFloating)
        ysToClear = @linesToClear(@curFloating)
        clearedLines = ysToClear.length > 0
        if clearedLines
          # Lines were cleared.  Pause the game timer.
          @stopGravity()
        @showNewFloatingBlock()
        @clearLines(ysToClear)
        if clearedLines
          _.delay((=>
            @fillLinesFromAbove(ysToClear)
            if ! @checkForGameOver()
              @startGravity()
          ), 500)
        else
          return false if @checkForGameOver()
      fell


    drop: ->
      # Get initial position.
      floating = @curFloating
      xys = _(floating.blocks).map(xyOf)
      minX1 = _(xy[0] for xy in xys).min()
      minY1 = _(xy[1] for xy in xys).min()

      # Drop.
      null while @fall()

      # Set position and size of tail.
      xys2 = _(floating.blocks).map(xyOf)
      @setElementXy(@tailSelector(), [minX1, minY1])

      minX = _(xy[0] for xy in xys ).min()
      maxX = _(xy[0] for xy in xys2).max()
      minY = _(xy[1] for xy in xys ).min()
      maxY = _(xy[1] for xy in xys2).min()
      $(@tailSelector()).width(@blockWidth * (maxX - minX + 1) - 2 * @borderWidth).height(@blockHeight * (maxY - minY + 1) - 2 * @borderHeight)

      # Show tail and hide after delay.
      $(@tailSelector()).show()
      _.delay((=>
        $e = $(@tailSelector())
        $e.animate({'height': 0, 'top': $e.position().top + $e.height()}, 500, 'easeOutExpo')
      ), 500)


    gravityInterval: -> 700


    startGravity: ->
      @fallTimer = window.setInterval(_.bind(@fall, @), @gravityInterval())


    stopGravity: ->
      window.clearInterval(@fallTimer)
      @fallTimer = null



  class TetrominoGame
    constructor: ->
      @localField = new PlayingField({ ordinal: 0 })
      @fields = [@localField]

    start: ->
      @localField.startGravity()



  # Exports
  root = exports ? this
  root.TetrominoEngine =
    Block: Block
    FloatingBlock: FloatingBlock
    PlayingField: PlayingField
    TetrominoGame: TetrominoGame

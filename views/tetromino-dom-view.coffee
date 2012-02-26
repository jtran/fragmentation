define ['jquery', 'jqueryui', 'util', 'underscore', 'decouple'], ($, jqueryui, util, _, decouple) ->

  class BlockDomView
    constructor: (@fieldView, @blockModel, @pieceModel) ->
      @elm = document.createElement('div')
      @elm.className = 'block next'
      switch @pieceModel.type
        when 0  # O
          $(@elm).addClass('light')
        when 1  # T
          $(@elm).addClass('light')
        when 2  # S
          $(@elm).addClass('dark')
        when 3  # Z
          $(@elm).addClass('dark')
        when 4  # L
          $(@elm).addClass('dark')
        when 5  # J
          $(@elm).addClass('dark')
        when 6  # I
          $(@elm).addClass('light')
        else
          throw "I don't know how to style a block of this type: " + @pieceModel.type

      # Use theme.
      $(@elm).addClass(@fieldView.getTheme())

      # Show it.
      $(@elm).appendTo(@fieldView.fieldSelector())

      decouple.on @blockModel, 'move Block', (caller, event) =>
        @fieldView.setElementXy(@elm, @blockModel.getXy())

      decouple.on @blockModel, 'activate Block', (caller, event) =>
        $(@elm).removeClass('next')

      decouple.on @blockModel, 'beforeClear Block', (caller, event) =>
        @expand()

      decouple.on @blockModel, 'afterClear Block', (caller, event) =>
        $(@elm).remove()

    expand: ->
      $(@elm).css {
        'border-radius': '0'
        'width': @fieldView.blockWidth + 'px'
        'left': (@blockModel.x * @fieldView.blockWidth + @fieldView.borderWidth) + 'px'
      }


  # View a PlayingField model in the DOM.
  class PlayingFieldDomView

    THEMES = ['blue', 'orange', 'yellow']

    constructor: (@fieldModel) ->
      @blockHeight = 20
      @blockWidth = 20
      @borderWidth = 1
      @borderHeight = 1

      @themeIndex = 0

      # Create elements on page.
      $('#background').append("""
        <div id="field_#{@fieldModel.ordinal}" class="field">
          <div class="field_background"></div>
          <div id="tail_#{@fieldModel.ordinal}" class="tail"></div>
        </div>
        """)

      # Use default theme.
      @setTheme(THEMES[@themeIndex]);

      decouple.on @fieldModel, 'new Block', (fieldModel, event, block, piece) =>
        new BlockDomView(@, block, piece)

      decouple.on @fieldModel, 'beforeDrop', (caller, event) => @beforeDrop()
      decouple.on @fieldModel, 'afterDrop',  (caller, event) => @afterDrop()

      decouple.on @fieldModel, 'clear', (caller, event, ys, blocks) =>
        decouple.trigger(blk, 'beforeClear Block') for blk in blocks
        _.delay((-> decouple.trigger(blk, 'afterClear Block') for blk in blocks), 500)

      decouple.on @fieldModel, 'gameOver', (caller, event) =>
        music = $('#music').get(0)
        music?.pause()


    fieldSelector: -> "#field_#{@fieldModel.ordinal}"
    tailSelector:  -> "#tail_#{@fieldModel.ordinal}"

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


    beforeDrop: ->
      # Get initial position.
      xys = (blk.getXy() for blk in @fieldModel.curFloating.blocks)
      @dropState =
        piece: @fieldModel.curFloating
        xys: xys
        minX1: _(xy[0] for xy in xys).min()
        minY1: _(xy[1] for xy in xys).min()


    afterDrop: ->
      # Set position and size of tail.
      xys2 = (blk.getXy() for blk in @dropState.piece.blocks)
      @setElementXy(@tailSelector(), [@dropState.minX1, @dropState.minY1])

      minX = _(xy[0] for xy in @dropState.xys ).min()
      maxX = _(xy[0] for xy in xys2           ).max()
      minY = _(xy[1] for xy in @dropState.xys ).min()
      maxY = _(xy[1] for xy in xys2           ).min()
      $(@tailSelector()).width(@blockWidth * (maxX - minX + 1) - 2 * @borderWidth).height(@blockHeight * (maxY - minY + 1) - 2 * @borderHeight)

      # Show tail and hide after delay.
      $(@tailSelector()).show()
      _.delay((=>
        $e = $(@tailSelector())
        $e.animate({'height': 0, 'top': $e.position().top + $e.height()}, 500, 'easeOutExpo')
      ), 500)

      @dropState = null




  # Exports
  root = exports ? this
  root.TetrominoDomView =
    BlockDomView: BlockDomView
    PlayingFieldDomView: PlayingFieldDomView

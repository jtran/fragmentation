#`import './jquery-1.6.2.min.js'`
#`import './underscore.js'`
`import util from './util.js'`
`import decouple from './decouple.js'`

class BlockDomView
  constructor: (@fieldView, @blockModel) ->
    @elm = document.createElement('div')
    @elm.className = 'block lit next'
    switch @blockModel.pieceType
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
      when 'opponent'
        $(@elm).addClass('light').addClass(@blockModel.pieceType)
      else
        throw "I don't know how to style a block of this type: #{@blockModel.pieceType}"

    # Initial position.
    @fieldView.setElementXy(@elm, @blockModel.getXy())

    # Use theme.
    $(@elm).addClass(@fieldView.getTheme())

    # Show it.
    $(@elm).appendTo(@fieldView.fieldSelector())

    decouple.on @blockModel, 'move Block', (caller, event) =>
      @fieldView.setElementXy(@elm, @blockModel.getXy())

    decouple.on @blockModel, 'activate Block', (caller, event) =>
      $(@elm).removeClass('next')

    decouple.on @blockModel, 'beforeClear Block', (caller, event) => @flickerOut()

    decouple.on @blockModel, 'afterClear Block', (caller, event) => @dispose()

    # This event occurs when deleting a block, but it's not from the
    # player clearing a line.
    decouple.on @blockModel, 'delete Block', (caller, event) => @dispose()

  dispose: ->
    $(@elm).remove()
    # Remove references to prevent memory leak.
    @elm = null
    decouple.removeAllForCaller(@blockModel)

  transition: (options = {}) ->
    options = _.extend { delaySequence: [50, 50, 50] }, options
    options.step?()
    seq = options.delaySequence
    [msecDelay, options.delaySequence] = [_.first(seq), _.rest(seq)] if seq?
    if msecDelay?
      _.delay (=> @transition(options)), msecDelay
    else
      options.callback?()

  flickerOut: (options = {}) ->
    userCallback = options.callback
    options.delaySequence = [20, 20, 20, 20]
    options.step = => $(@elm).toggleClass('lit')
    options.callback = => $(@elm).removeClass('lit'); userCallback?()
    @transition(options)


# View a PlayingField model in the DOM.
class PlayingFieldDomView

  THEMES = ['blue', 'orange', 'yellow']

  constructor: (@fieldModel, options) ->
    @ordinal = options.ordinal
    @domId = _.uniqueId()
    @blockHeight = 20
    @blockWidth = 20
    @borderWidth = 1
    @borderHeight = 1
    @marginLeft = 20
    @themeIndex = null

    # Create elements on page.  Wrap in a lambda so that references
    # don't leak to lambdas further down.
    (=>
      $field = $("""
        <div id="field_#{@domId}" class="field" style="display: none">
          <div class="field_background"></div>
          <div id="tail_#{@domId}" class="tail"></div>
        </div>
      """)
      fieldPixelWidth = @fieldPixelWidth()
      fieldPixelHeight = @fieldPixelHeight()
      $field.css
        left: "#{@ordinal * (fieldPixelWidth + @marginLeft) + @marginLeft}px"
        width: "#{fieldPixelWidth}px"
        height: "#{fieldPixelHeight}px"
      $field.appendTo('#background')
      $field.fadeIn('fast')
    )()

    # Use theme.
    @setThemeIndex(options.themeIndex ? 0)

    decouple.on @fieldModel, 'new Block', (fieldModel, event, block) =>
      new BlockDomView(@, block)

    decouple.on @fieldModel, 'beforeDrop', (caller, event) => @beforeDrop()
    decouple.on @fieldModel, 'afterDrop',  (caller, event) => @afterDrop()

    decouple.on @fieldModel, 'clear', (caller, event, ys, blocks) =>
      decouple.trigger(blk, 'beforeClear Block') for blk in blocks
      _.delay((-> decouple.trigger(blk, 'afterClear Block') for blk in blocks), 500)

    decouple.on @fieldModel, 'gameOver', (caller, event) =>
      music = $('#music').get(0)
      music?.pause()


  leaveGame: (callback = null) =>
    $(@fieldSelector()).fadeOut 'slow', =>
      decouple.trigger(blk, 'delete Block') for blk in @fieldModel.allBlocks()
      $(@fieldSelector()).remove()
      callback?()


  fieldPixelWidth: -> @blockWidth * @fieldModel.fieldWidth + 2 * @borderWidth
  fieldPixelHeight: -> @blockHeight * @fieldModel.fieldHeight + 2 * @borderHeight

  fieldSelector: -> "#field_#{@domId}"
  tailSelector:  -> "#tail_#{@domId}"

  getTheme: -> THEMES[@themeIndex]

  setThemeIndex: (themeIndex) ->
    $('.block, .tail', @fieldSelector()).removeClass(THEMES[@themeIndex]) if @themeIndex?
    @themeIndex = themeIndex
    $('.block, .tail', @fieldSelector()).addClass(THEMES[themeIndex])

  setOrdinal: (ordinal) ->
    @ordinal = ordinal
    $(@fieldSelector()).css('left', "#{@ordinal * (@fieldPixelWidth() + @marginLeft) + @marginLeft}px")

  setPosition: (sel, left, top) ->
    $(sel).css({'left': left + 'px', 'top': top + 'px'})

  setElementXy: (sel, xy) ->
    @setPosition(sel,
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

export default
  BlockDomView: BlockDomView
  PlayingFieldDomView: PlayingFieldDomView

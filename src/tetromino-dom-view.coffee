#import './jquery-1.6.2.min.js'
#import './underscore.js'

import decouple from './decouple.js'
import { PlayingField } from './tetromino-engine.js'

export class BlockDomView
  constructor: (@fieldView, @blockModel) ->
    @elm = document.createElement('div')
    @elm.className = 'block lit'
    $(@elm).addClass('next') if not @blockModel.isActivated
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
        throw new Error("I don't know how to style a block of this type: #{@blockModel.pieceType}")

    # Initial position.
    @fieldView.setElementXy(@elm, @blockModel.getXy())

    # Use theme.
    $(@elm).addClass(@fieldView.getTheme())

    # Show it.
    $(@elm).appendTo(@fieldView.fieldSelector())

    decouple.on @blockModel, 'move Block', @, (caller, event) =>
      @fieldView.setElementXy(@elm, @blockModel.getXy())

    decouple.on @blockModel, 'isActivatedChange', @, (caller, event, isActivated) =>
      if isActivated
        $(@elm).removeClass('next')
      else
        $(@elm).addClass('next')

    decouple.on @blockModel, 'clearBlock', @, (caller, event) => @flickerOut()

    decouple.on @blockModel, 'removeBlock', @, (caller, event) => @dispose()

    # This gets triggered when a parent element is about to be removed from the
    # DOM, and we should stop listening to the model.  We shouldn't bother
    # removing from the DOM.
    decouple.on @blockModel, 'abandonView', @, (caller, event, fieldView) =>
      if @fieldView == fieldView
        @dispose(false)

  dispose: (removeElement = true) ->
    $(@elm).remove() if removeElement && @elm?
    # Remove references to prevent memory leak.
    @elm = null
    decouple.removeAllForTarget(@)

  transition: (options = {}) ->
    options = Object.assign({ delaySequence: [50, 50, 50] }, options)
    options.step?()
    seq = options.delaySequence
    [msecDelay, options.delaySequence...] = seq if seq?
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
export class PlayingFieldDomView

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
      pausedExtraClasses = if @fieldModel.isPaused() then ' visible' else ''
      $field = $("""
        <div id="field_#{@domId}" class="field" style="display: none">
          <div class="field_background">
            <div id="paused_#{@domId}" class="paused#{pausedExtraClasses}">PAUSED</div>
          </div>
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

    if @fieldModel.curFloating?
      new BlockDomView(@, blk) for blk in @fieldModel.curFloating.blocks
    if @fieldModel.nextFloating?
      new BlockDomView(@, blk) for blk in @fieldModel.nextFloating.blocks
    for row in @fieldModel.blocks
      for blk in row when blk?
        new BlockDomView(@, blk)

    decouple.on @fieldModel, 'addBlock', @, (fieldModel, event, block) =>
      new BlockDomView(@, block)

    decouple.on @fieldModel, 'beforeDrop', @, (caller, event) => @beforeDrop()
    decouple.on @fieldModel, 'afterDrop',  @, (caller, event) => @afterDrop()

    decouple.on @fieldModel, 'stateChange', @, (caller, event, newState) =>
      if newState == PlayingField.STATE_PAUSED
        $(@pausedSelector()).addClass('visible')
      else
        $(@pausedSelector()).removeClass('visible')


  leaveGame: (callback = null) =>
    $(@fieldSelector()).fadeOut 'slow', =>
      # TODO: The view shouldn't be triggering events on the model.
      decouple.trigger(blk, 'abandonView', @) for blk in @fieldModel.allBlocks()
      $(@fieldSelector()).remove()
      decouple.removeAllForTarget(@)
      callback?()


  fieldPixelWidth: -> @blockWidth * @fieldModel.fieldWidth + 2 * @borderWidth
  fieldPixelHeight: -> @blockHeight * @fieldModel.fieldHeight + 2 * @borderHeight

  fieldSelector: -> "#field_#{@domId}"
  pausedSelector: -> "#paused_#{@domId}"
  tailSelector:  -> "#tail_#{@domId}"

  getTheme: -> THEMES[@themeIndex]

  setThemeIndex: (themeIndex) ->
    $('.block, .paused, .tail', @fieldSelector()).removeClass(THEMES[@themeIndex]) if @themeIndex?
    @themeIndex = themeIndex
    $('.block, .paused, .tail', @fieldSelector()).addClass(THEMES[themeIndex])

  getOrdinal: -> @ordinal

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

export default { BlockDomView, PlayingFieldDomView }

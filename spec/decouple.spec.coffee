import decouple from '../lib/decouple.js'

describe 'decouple', ->

  afterEach ->
    decouple.reset()

  it "calls listener when triggered", ->
    called = false
    fn = (caller, event) -> called = true
    decouple.on null, 'someEvent', fn
    decouple.trigger {}, 'someEvent'
    expect(called).to.equal true

  it "calls listener filtered by caller when triggered", ->
    called1 = false
    fn1 = (caller, event) -> called1 = true
    called2 = false
    fn2 = (caller, event) -> called2 = true
    caller = {}
    decouple.on caller, 'someEvent', fn1
    decouple.on {}, 'someEvent', fn2
    decouple.trigger caller, 'someEvent'
    expect(called1).to.equal true
    expect(called2).to.equal false

  it "removes bindings for target", ->
    observer = {}
    fn = (caller, event) -> true
    obj = {}
    decouple.on obj, 'someEvent', observer, fn
    binding = decouple.bindings[0]
    expect(binding.target).to.equal(observer)
    decouple.removeAllForTarget(observer)
    expect(decouple.bindings).not.to.include(binding)

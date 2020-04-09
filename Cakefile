{print} = require 'util'
{spawn} = require 'child_process'

spawnCoffee = (options, callback = null) ->
  coffee = spawn 'coffee', options
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

build = (callback) ->
  spawnCoffee ['--compile', '--output', 'lib', 'src'], ->
    # Compile the server.
    spawnCoffee ['--compile', 'tetromino-server.coffee'], ->
      callback?()

task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  build()

task 'test', 'Build and run all tests', (options) ->
  build ->
    jasmine = require 'jasmine-node'

    options =
      specFolders: [__dirname + '/spec']
      onComplete: (runner, log) ->
        if runner.results().failedCount == 0
          process.exit 0
        else
          process.exit 1
      regExpSpec: /\.(js|coffee)$/i
      showColors: true
      isVerbose: false
      useRequireJs: __dirname + '/spec/requirejs-setup.js'
    jasmine.executeSpecsInFolder options

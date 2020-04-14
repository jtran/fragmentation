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
  spawnCoffee ['--compile', '--bare', '--output', 'lib', 'src'], ->
    # Compile the server.
    spawnCoffee ['--compile', '--bare', 'tetromino-server.coffee'], ->
      # compile the tests.
      spawnCoffee ['--compile', '--bare', '--output', 'test-build', 'spec'], ->
        callback?()

task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  build()

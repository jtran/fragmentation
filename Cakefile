task 'test', 'Run all tests', (options) ->
  jasmine = require 'jasmine-node'

  showColors = true
  isVerbose = false
  teamcity = null
  useRequireJs = false

  jasmine.executeSpecsInFolder __dirname + '/spec', ((runner, log) ->
    if runner.results().failedCount == 0
      process.exit 0
    else
      process.exit 1
  ), isVerbose, showColors, teamcity, useRequireJs,
  /\.(js|coffee)$/, { report: null }


task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  {exec} = require 'child_process'
  exec 'coffee --compile --output lib/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

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

// This needs to be JavaScript because jasmine-node runs this in the context of
// every spec file in a non-standard way.
//
// See https://github.com/mhevery/jasmine-node/blob/3.0.0/lib/jasmine-node/requirejs-runner.js#L81
requirejs = require('requirejs');
requirejs.config({
  baseUrl: __dirname + '/../lib',
});

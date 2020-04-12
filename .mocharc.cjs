// set up for mocha tests
const sinonChai = require('sinon-chai');
const chai = require('chai');
const sinon = require('sinon');

chai.use(sinonChai);

global.should = chai.should();
global.expect = chai.expect;
global.spyOn = sinon.spy;

module.exports = {};

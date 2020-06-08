### Fragmentation

Multiplayer tetromino game inspired by Tron: Legacy that runs in a browser.
Play by sharing a link.

<img src="doc/screenshot.png" alt="Game screenshot" width="465">

### Installation

Requires node v14.

    npm install

### Usage

Run the server.

    npm start

This also builds the project from `src/*.coffee` to `lib/*.js` using the
CoffeeScript2 compiler.

Run the following in another shell to recompile files in `src/` that have
changed so that you can update the client by refreshing the web browser.  This
will not update server-side code.

    npm run watch

### Testing

Run the tests.

    npm test

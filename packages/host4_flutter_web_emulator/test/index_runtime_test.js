'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  const html = fs.readFileSync('assets/emulator/index.html', 'utf8');
  const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  assert.ok(scripts.length > 0, 'index.html must contain an inline runtime');

  const messages = [];
  const commands = [];
  const emulator = {
    exit() {},
    sendCommand(command) {
      commands.push(command);
    },
  };
  const window = {
    JsBridge: {
      postMessage(value) {
        messages.push(JSON.parse(value));
      },
    },
    Nostalgist: {
      async launch() {
        return emulator;
      },
    },
  };
  const context = {
    Blob,
    FileReader: class {},
    Uint8Array,
    atob,
    console,
    document: {getElementById: () => ({})},
    window,
  };

  vm.runInNewContext(scripts.at(-1)[1], context);
  await window.Host4WebEmulator.launch({
    requestId: 'launch-1',
    system: 'gba',
    core: 'mgba',
    romFileUrl: 'file:///demo.gba',
  });

  window.Host4WebEmulator.setRate(2, 'rate-2');
  assert.deepEqual(commands, ['FAST_FORWARD']);
  assert.equal(messages.at(-1).payload.ok, true);
  assert.equal(messages.at(-1).payload.data.rate, 2);

  window.Host4WebEmulator.setRate(2, 'rate-2-repeat');
  assert.deepEqual(commands, ['FAST_FORWARD']);

  window.Host4WebEmulator.setRate(1, 'rate-1');
  assert.deepEqual(commands, ['FAST_FORWARD', 'FAST_FORWARD']);
  assert.equal(messages.at(-1).payload.ok, true);
  assert.equal(messages.at(-1).payload.data.rate, 1);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

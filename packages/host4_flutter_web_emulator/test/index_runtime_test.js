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
  const stateLifecycle = [];
  const animationFrames = [];
  let launchOptions;
  let status = 'running';
  const emulator = {
    exit() {},
    getStatus() {
      return status;
    },
    pause() {
      status = 'paused';
      stateLifecycle.push('pause');
    },
    resume() {
      status = 'running';
      stateLifecycle.push('resume');
    },
    async loadState() {
      stateLifecycle.push(`loadState:${status}`);
    },
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
      async launch(options) {
        launchOptions = options;
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
    requestAnimationFrame(callback) {
      animationFrames.push(callback);
    },
    window,
  };

  async function flushAnimationFrame() {
    const callbacks = animationFrames.splice(0);
    callbacks.forEach((callback) => callback());
    await Promise.resolve();
  }

  vm.runInNewContext(scripts.at(-1)[1], context);
  await window.Host4WebEmulator.launch({
    requestId: 'launch-1',
    system: 'gba',
    core: 'mgba',
    romFileUrl: 'file:///demo.gba',
  });
  assert.equal(
    launchOptions.retroarchConfig?.fastforward_ratio,
    2,
    'the 2.0x UI must launch RetroArch with a real 2x frame cap',
  );

  window.Host4WebEmulator.pause('pause-before-load');
  await window.Host4WebEmulator.loadState('load-while-paused', 'U1RBVEU=');
  assert.deepEqual(stateLifecycle, [
    'pause',
    'resume',
    'loadState:running',
  ]);
  assert.equal(messages.at(-1).method, 'stateLoaded');

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

  window.Host4WebEmulator.pause('pause-rate');
  window.Host4WebEmulator.setRate(2, 'rate-while-paused');
  assert.equal(messages.at(-1).payload.ok, false);
  assert.deepEqual(commands, ['FAST_FORWARD', 'FAST_FORWARD']);

  const resumeWithRate = window.Host4WebEmulator.resume('resume-rate', 2);
  assert.deepEqual(commands, ['FAST_FORWARD', 'FAST_FORWARD']);
  await flushAnimationFrame();
  assert.deepEqual(commands, ['FAST_FORWARD', 'FAST_FORWARD']);
  await flushAnimationFrame();
  await resumeWithRate;
  assert.deepEqual(commands, [
    'FAST_FORWARD',
    'FAST_FORWARD',
    'FAST_FORWARD',
  ]);
  assert.equal(messages.at(-1).method, 'resumed');
  assert.equal(messages.at(-1).payload.data.rate, 2);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

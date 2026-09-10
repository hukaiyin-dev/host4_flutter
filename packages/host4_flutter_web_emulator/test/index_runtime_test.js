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
  let activeCanvas = {
    id: 'canvas', width: 844, height: 390, isConnected: true,
    getBoundingClientRect: () => ({x: 0, y: 0, width: 390, height: 844}),
  };
  const emulator = {
    getCanvas() { return activeCanvas; },
    getEmscripten() {
      return { Browser: { mainLoop: {
        currentlyRunningMainloop: 0, currentFrameNumber: 123,
        timingMode: 1, timingValue: 1, queue: [],
      } }, Module: { ctx: {
        VIEWPORT: 1, SCISSOR_BOX: 2, SCISSOR_TEST: 3,
        drawingBufferWidth: 1179, drawingBufferHeight: 2556,
        isContextLost: () => false,
        getParameter: () => [0, 0, 2556, 1179],
        isEnabled: () => false,
      } } };
    },
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
    getComputedStyle: () => ({width: '390px', height: '844px', objectFit: 'contain'}),
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
    document: {getElementById: () => null, hasFocus: () => true, visibilityState: 'visible'},
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
  assert.equal(messages.filter(message => message.method === 'diagnostic').length, 0,
    'normal boot must not emit temporary diagnostics');
  await window.Host4WebEmulator.launch({
    requestId: 'launch-1',
    system: 'gba',
    core: 'mgba',
    romFileUrl: 'file:///demo.gba',
    coreJsBase64: Buffer.from('var Module = {}; var RWA = globalThis.testAudio;').toString('base64'),
    coreWasmBase64: 'AA==',
  });
  const patchedCore = await launchOptions.resolveCoreJs();
  let resumeCalls = 0;
  const testAudio = {
    context: { state: 'interrupted', currentTime: 12,
      async resume() { resumeCalls++; this.state = 'running'; } },
    endTime: 1000, currentTimeDiff: -50, contextRunning: false,
  };
  const coreContext = { testAudio, performance: { now: () => 25000 } };
  vm.runInNewContext(await patchedCore.text(), coreContext);
  assert.equal(await coreContext.Module.host4RecoverAudio(), true);
  assert.equal(resumeCalls, 1);
  assert.equal(testAudio.endTime, 12);
  assert.equal(testAudio.currentTimeDiff, 13);
  assert.equal(testAudio.contextRunning, true);
  testAudio.context.state = 'closed';
  assert.equal(await coreContext.Module.host4RecoverAudio(), false);
  assert.equal(resumeCalls, 1);
  testAudio.context.state = 'suspended';
  testAudio.context.resume = async () => { throw new Error('resume denied'); };
  await assert.rejects(coreContext.Module.host4RecoverAudio(), /resume denied/);
  window.Host4WebEmulator.diagnose('after_canvas_rename');
  let diagnostic = messages.at(-1).payload;
  assert.equal(diagnostic.canvasId, 'canvas');
  assert.deepEqual(diagnostic.canvasBuffer, [844, 390]);
  assert.deepEqual(diagnostic.canvasRect, [0, 0, 390, 844]);
  assert.equal(diagnostic.mainLoop.generation, 0);
  assert.equal(diagnostic.mainLoop.frameNumber, 123);
  assert.deepEqual(diagnostic.graphics.drawingBuffer, [1179, 2556]);
  assert.deepEqual(diagnostic.graphics.viewport, [0, 0, 2556, 1179]);
  activeCanvas = null;
  window.Host4WebEmulator.diagnose('missing_canvas');
  diagnostic = messages.at(-1).payload;
  assert.equal(diagnostic.canvasBuffer, null);
  assert.equal(diagnostic.status, 'running');
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

  // Real core layout: Module and RWA live inside an ESM factory, not globally.
  const esmSource = `var sourceUrl = import.meta.url;
    function createCore() {
      var Module = {}, RWA = globalThis.testAudio;
      var readyPromiseResolve = value => { globalThis.resolvedModule = value; };
      readyPromiseResolve(Module);
      return Module;
    }`;
  vm.runInNewContext(scripts.at(-1)[1], context);
  await window.Host4WebEmulator.launch({
    core: 'fceumm', romFileUrl: 'test.nes',
    coreJsBase64: Buffer.from(esmSource).toString('base64'), coreWasmBase64: 'AA==',
  });
  const esmPatched = await (await launchOptions.resolveCoreJs()).text();
  assert.equal((esmPatched.match(/readyPromiseResolve\(Module\)/g) || []).length, 1);
  const factoryContext = { testAudio, performance: { now: () => 25000 } };
  vm.runInNewContext(esmPatched.replace('import.meta.url', '"test.mjs"'), factoryContext);
  const factoryModule = factoryContext.createCore();
  assert.equal(factoryContext.resolvedModule, factoryModule);
  assert.equal(typeof factoryModule.host4RecoverAudio, 'function');
  testAudio.context.state = 'running';
  testAudio.endTime = 1000;
  assert.equal(await factoryModule.host4RecoverAudio(), true);
  assert.equal(testAudio.endTime, 12);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

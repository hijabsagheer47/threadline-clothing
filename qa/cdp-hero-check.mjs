/* CDP check for the Fashlab hero 3D scene.
   Usage: node qa/cdp-hero-check.mjs <port> <url> <outPrefix> */
import fs from 'node:fs';
const [port, url, outPrefix] = process.argv.slice(2);

const ver = await (await fetch(`http://127.0.0.1:${port}/json/version`)).json();
const target = await (await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`, { method: 'PUT' })).json();

const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });

let id = 0;
const pending = new Map();
const consoleErrors = [];
ws.onmessage = (ev) => {
  const m = JSON.parse(ev.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  if (m.method === 'Runtime.exceptionThrown') {
    consoleErrors.push('EXCEPTION: ' + (m.params.exceptionDetails.exception?.description || m.params.exceptionDetails.text));
  }
  if (m.method === 'Runtime.consoleAPICalled' && ['error', 'warning'].includes(m.params.type)) {
    consoleErrors.push(m.params.type.toUpperCase() + ': ' + m.params.args.map(a => a.value ?? a.description ?? '').join(' '));
  }
  if (m.method === 'Log.entryAdded' && m.params.entry.level === 'error') {
    consoleErrors.push('LOG: ' + m.params.entry.text);
  }
};
const send = (method, params = {}) => new Promise((resolve) => {
  const i = ++id;
  pending.set(i, (m) => resolve(m.result ?? m.error));
  ws.send(JSON.stringify({ id: i, method, params }));
});
const evalJs = async (expression) => {
  const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  return r.result?.value;
};

await send('Page.enable');
await send('Runtime.enable');
await send('Log.enable');
await send('Page.addScriptToEvaluateOnNewDocument', {
  source: `window.__rafTicks = 0;
    (function(){ const o = window.requestAnimationFrame.bind(window);
      window.requestAnimationFrame = function(cb){ window.__rafTicks++; return o(cb); }; })();`
});

await new Promise(r => setTimeout(r, 8000)); // let the scene boot + animate

const state = await evalJs(`(function(){
  const c = document.querySelector('.lx-hero-3d');
  if (!c) return { found: false };
  return {
    found: true,
    isLive: c.classList.contains('is-live'),
    px: c.width + 'x' + c.height,
    css: c.clientWidth + 'x' + c.clientHeight,
    opacity: getComputedStyle(c).opacity,
    three: !!window.THREE,
    rafTicks: window.__rafTicks
  };
})()`);

// two direct reads of the WebGL canvas, 700ms apart
const shot1 = await evalJs(`(function(){ const c = document.querySelector('.lx-hero-3d'); return c ? c.toDataURL('image/png') : null; })()`);
await new Promise(r => setTimeout(r, 700));
const shot2 = await evalJs(`(function(){ const c = document.querySelector('.lx-hero-3d'); return c ? c.toDataURL('image/png') : null; })()`);
const rafAfter = await evalJs('window.__rafTicks');

if (shot1) fs.writeFileSync(outPrefix + '-canvas1.png', Buffer.from(shot1.split(',')[1], 'base64'));
if (shot2) fs.writeFileSync(outPrefix + '-canvas2.png', Buffer.from(shot2.split(',')[1], 'base64'));

console.log(JSON.stringify({ state, rafAfter, consoleErrors, shot1Len: shot1?.length, shot2Len: shot2?.length }, null, 2));
ws.close();
process.exit(0);

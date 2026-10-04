/* Capture composited frames of the hero with layers isolated, via CDP.
   Usage: node qa/cdp-hero-shots.mjs <port> <url> <outDir> */
import fs from 'node:fs';
const [port, url, outDir] = process.argv.slice(2);

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
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const shot = async (name) => {
  const r = await send('Page.captureScreenshot', {
    format: 'png',
    clip: { x: 0, y: 0, width: 1440, height: 700, scale: 1 }
  });
  if (r.data) fs.writeFileSync(`${outDir}/${name}.png`, Buffer.from(r.data, 'base64'));
  return !!r.data;
};

await send('Page.enable');
await send('Runtime.enable');
await send('Log.enable');

await sleep(9000); // scene boots + animates

// state check
const state = await (await send('Runtime.evaluate', {
  expression: `(function(){
    const c = document.querySelector('.lx-hero-3d');
    return c ? { isLive: c.classList.contains('is-live'), px: c.width + 'x' + c.height,
                 three: !!window.THREE, opacity: getComputedStyle(c).opacity } : { missing: true };
  })()`,
  returnByValue: true
})).result?.value;

// Layer isolation: hide every non-WebGL animated layer of the hero
await send('Runtime.evaluate', {
  expression: `(function(){
    const s = document.createElement('style');
    s.id = 'qa-isolate';
    s.textContent = '.lx-hero-particles,.lx-fabric-canvas,.lx-float-card,.lx-hero-frame-ghost{visibility:hidden!important}';
    document.head.appendChild(s);
    return true;
  })()`,
  returnByValue: true
});
await sleep(600);
await shot('A-webgl-t1');
await sleep(700);
await shot('B-webgl-t2'); // WebGL still visible — animation diff A→B must come from WebGL only

// now hide the WebGL canvas too → baseline of everything else
await send('Runtime.evaluate', {
  expression: `(function(){
    document.getElementById('qa-isolate').textContent +=
      ',.lx-hero-3d{visibility:hidden!important}';
    return true;
  })()`,
  returnByValue: true
});
await sleep(600);
await shot('C-baseline');

console.log(JSON.stringify({ state, consoleErrors }, null, 2));
ws.close();
process.exit(0);

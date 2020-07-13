/**
 * Returns a UUID
 *
 * Lovingly taken from https://stackoverflow.com/a/2117523/1708147
 * Thanks!
 */
function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = (Math.random() * 16) | 0,
      v = c == 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

const FALLBACK =
  '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="180" stroke-linejoin="round">' +
  '  <path stroke="#DDD" stroke-width="25" d="M99,18 15,162H183z"/>' +
  '  <path stroke-width="17" fill="#FFF" d="M99,18 15,162H183z" stroke="#eee"/>' +
  '  <path d="M91,70a9,9 0 0,1 18,0l-5,50a4,4 0 0,1-8,0z" fill="#aaa"/>' +
  '  <circle cy="138" r="9" cx="100" fill="#aaa"/>' +
  '</svg>';

const requests = new Map();

self.addEventListener('install', event => {
  console.log('[sw] Installing service worker...');

  event.waitUntil(install());
});

self.addEventListener('activate', event => {
  // Start intercepting immediately...
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', event => {
  console.log('[sw] handling fetch for ', event.request);

  if (/\.png$/.test(event.request.url)) {
    const path = event.request.url.replace(/^https?:\/\/[^\/]+\//, '');
    const requestId = uuidv4();
    const response = self.clients.get(event.clientId).then(client => {
      return new Promise((resolve, reject) => {
        requests.set(requestId, {
          resolve: val => {
            console.log('[sw] resolving with val', val);
            resolve(val);
          },
          reject,
        });

        client.postMessage({ path, requestId });
      });
    });

    event.respondWith(response);
  }
});

self.addEventListener('message', event => {
  console.log('[sw] got a message', event);

  const { type, payload } = event.data;

  if (type !== 'gitlab-ide-response') {
    return;
  }

  const { requestId, content, contentType } = payload;

  if (!requests.has(requestId)) {
    console.error('[sw] got a response for a request that does not exist', requestId);
    return;
  }

  const { resolve, reject } = requests.get(requestId);
  requests.delete(requestId);

  console.log('[sw] resolve', contentType, content);
  resolve(
    new Response(content, {
      headers: {
        'Content-Type': contentType,
      },
    }),
  );
});

function install() {
  return Promise.resolve().then(() => {
    return self.skipWaiting();
  });
}

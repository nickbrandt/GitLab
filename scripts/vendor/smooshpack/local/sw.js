const FALLBACK =
  '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="180" stroke-linejoin="round">' +
  '  <path stroke="#DDD" stroke-width="25" d="M99,18 15,162H183z"/>' +
  '  <path stroke-width="17" fill="#FFF" d="M99,18 15,162H183z" stroke="#eee"/>' +
  '  <path d="M91,70a9,9 0 0,1 18,0l-5,50a4,4 0 0,1-8,0z" fill="#aaa"/>' +
  '  <circle cy="138" r="9" cx="100" fill="#aaa"/>' +
  '</svg>';

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
    console.log('[sw] handling image!!');
    const response = new Response(FALLBACK, {
      headers: {
        'Content-Type': 'image/svg+xml',
      },
    });
    event.respondWith(response);
  }
});

function install() {
  return Promise.resolve().then(() => {
    return self.skipWaiting();
  });
}

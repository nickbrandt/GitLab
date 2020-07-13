main();

function main() {
  if (!('serviceWorker' in navigator)) {
    console.log('Service workers are not supported.');
    return;
  }

  window.addEventListener('message', event => {
    console.log('[main] got an iframe message!', event);

    const { type, payload } = event.data;

    if (type !== 'gitlab-ide-response') {
      return;
    }

    navigator.serviceWorker.controller.postMessage({
      type,
      payload,
    });
  });

  // Register a service worker hosted at the root of the
  // site using the default scope.
  navigator.serviceWorker.register('/sw.js', { scope: '/' }).then(
    function(registration) {
      console.log('Service worker registration succeeded:', registration);
    },
    /*catch*/ function(error) {
      console.log('Service worker registration failed:', error);
    },
  );

  navigator.serviceWorker.addEventListener('message', event => {
    console.log('[main] receiving message', event);
    window.parent.postMessage(
      {
        type: 'gitlab-ide',
        payload: event.data,
      },
      '*',
    );

    navigator.serviceWorker.controller.postMessage({
      message: 'Got a message!',
    });
  });
}

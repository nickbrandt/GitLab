main();

function main() {
  if (!('serviceWorker' in navigator)) {
    console.log('Service workers are not supported.');
    return;
  }

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

  // NOTE: Something like this might be needed...
  // for now it just keeps reloading :|
  //
  // navigator.serviceWorker.ready.then(() => {
  //   window.location.reload();
  // });

  navigator.serviceWorker.addEventListener('message', event => {
    console.log('[main] receiving message', event);
    const path = event.data.path;

    window.parent.postMessage(
      {
        type: 'gitlab-ide',
        data: event.data,
      },
      '*',
    );

    navigator.serviceWorker.controller.postMessage({
      message: 'Got a message!',
    });
  });

  window.addEventListener('message', e => {
    console.log('[main] received a message from iframe window', e);
  });
}

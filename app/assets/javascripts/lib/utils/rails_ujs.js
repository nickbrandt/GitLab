import Rails from '@rails/ujs';
import csrf from './csrf';

export const initRails = () => {
  // eslint-disable-next-line no-underscore-dangle
  if (!window._rails_loaded) {
    Rails.start();

    // Count XHR requests for tests. See spec/support/helpers/wait_for_requests.rb
    window.pendingRailsUJSRequests = 0;
    document.body.addEventListener('ajax:complete', () => {
      window.pendingRailsUJSRequests -= 1;
    });

    document.body.addEventListener('ajax:beforeSend', () => {
      window.pendingRailsUJSRequests += 1;
    });
  }
};

// use our cached token for any Rails-generated AJAX requests
Rails.csrfToken = () => csrf.token;

export { Rails };

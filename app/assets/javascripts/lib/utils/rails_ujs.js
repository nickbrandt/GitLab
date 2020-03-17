import Rails from '@rails/ujs';
import csrf from './csrf';

export const initRails = () => {
  // eslint-disable-next-line no-underscore-dangle
  if (!window._rails_loaded) {
    Rails.start();
  }
};

// use our cached token for any Rails-generated AJAX requests
Rails.csrfToken = () => csrf.token;

export { Rails };

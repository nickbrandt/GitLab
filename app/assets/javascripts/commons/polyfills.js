// Browser polyfills

/**
 * Polyfill: fetch
 * @what https://fetch.spec.whatwg.org/
 * @why Because Apollo GraphQL client relies on fetch
 * @browsers Internet Explorer 11
 * @see https://caniuse.com/#feat=fetch
 */
import 'unfetch/polyfill/index';
import 'formdata-polyfill';
import './polyfills/custom_event';
import './polyfills/element';
import './polyfills/event';
import './polyfills/nodelist';
import './polyfills/request_idle_callback';
import './polyfills/svg';

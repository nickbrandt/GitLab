/**
 * setWindowLocation allows for setting properties of `window.location`
 * (doing so directly is causing an error in jsdom)
 *
 * Example usage:
 * assert(window.location.hash === undefined);
 * setWindowLocation({
 *    href: 'http://example.com#foo'
 * })
 * assert(window.location.hash === '#foo');
 *
 * More information:
 * https://github.com/facebook/jest/issues/890
 *
 * @param value
 */
export default function setWindowLocation(value) {
  Object.defineProperty(window, 'location', {
    writable: true,
    value,
  });
}

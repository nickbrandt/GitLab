/**
 * DO NOT USE!
 *
 * This is a module meant to encapsulate a legacy bit of calculation so that it can
 * be easily mocked in Jest to fix performance and degredation issues.
 */
export default window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.setTimeout;

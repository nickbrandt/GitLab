import initGeoNodes from 'ee/geo_nodes';
import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', initGeoNodes);
document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.user-callout');

  if (callout) new PersistentUserCallout(callout); // eslint-disable-line no-new
});

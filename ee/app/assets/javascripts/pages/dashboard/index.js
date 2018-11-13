import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.js-gold-trial-callout');

  if (callout) new PersistentUserCallout(callout); // eslint-disable-line no-new
});

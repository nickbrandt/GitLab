import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () => {
  const callout = document.querySelector('.js-gold-trial-callout');
  PersistentUserCallout.factory(callout);
});

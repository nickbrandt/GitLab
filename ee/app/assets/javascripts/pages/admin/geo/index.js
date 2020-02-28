import initVueAlerts from '~/vue_alerts';
import showToast from '~/vue_shared/plugins/global_toast';

document.addEventListener('DOMContentLoaded', () => {
  initVueAlerts();

  const toasts = document.querySelectorAll('.js-toast-message');
  toasts.forEach(toast => showToast(toast.dataset.message));
});

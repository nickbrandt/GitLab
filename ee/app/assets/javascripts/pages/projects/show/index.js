import '~/pages/projects/show/index';
import initVueAlerts from '~/vue_alerts';
import initNamespaceStorageLimitAlert from 'ee/namespace_storage_limit_alert';

document.addEventListener('DOMContentLoaded', () => {
  initVueAlerts();
  initNamespaceStorageLimitAlert();
});

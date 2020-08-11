import initSecurityDashboardSettings from 'ee/security_dashboard/instance_dashboard_settings_init';

document.addEventListener('DOMContentLoaded', () => {
  initSecurityDashboardSettings(document.getElementById('js-security'));
});

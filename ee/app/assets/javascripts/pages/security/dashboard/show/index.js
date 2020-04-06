import initInstanceSecurityDashboard from 'ee/security_dashboard/instance_init';
import initFirstClassSecurityDashboard from 'ee/security_dashboard/first_class_init';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';

document.addEventListener('DOMContentLoaded', () => {
  if (gon.features?.firstClassVulnerabilities) {
    initFirstClassSecurityDashboard(
      document.getElementById('js-security'),
      DASHBOARD_TYPES.INSTANCE,
    );
  } else if (gon.features?.instanceSecurityDashboard) {
    initInstanceSecurityDashboard();
  }
});

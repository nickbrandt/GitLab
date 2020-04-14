import initGroupSecurityDashboard from 'ee/security_dashboard/group_init';
import initFirstClassSecurityDashboard from 'ee/security_dashboard/first_class_init';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';

document.addEventListener('DOMContentLoaded', () => {
  if (gon.features?.firstClassVulnerabilities) {
    initFirstClassSecurityDashboard(
      document.getElementById('js-group-security-dashboard'),
      DASHBOARD_TYPES.GROUP,
    );
  } else {
    initGroupSecurityDashboard();
  }
});

import initProjectSecurityDashboard from 'ee/security_dashboard/project_init';
import initFirstClassSecurityDashboard from 'ee/security_dashboard/first_class_init';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';

document.addEventListener('DOMContentLoaded', () => {
  if (gon.features?.firstClassVulnerabilities) {
    initFirstClassSecurityDashboard(
      document.getElementById('js-security-report-app'),
      DASHBOARD_TYPES.PROJECT,
    );
  } else {
    initProjectSecurityDashboard();
  }
});

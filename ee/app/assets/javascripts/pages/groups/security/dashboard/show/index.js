import initSecurityDashboard from 'ee/security_dashboard/index';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';

document.addEventListener('DOMContentLoaded', () => {
  initSecurityDashboard(DASHBOARD_TYPES.GROUP);
});

import initGroupDetails from '~/pages/groups/shared/group_details';
import initSecurityDashboard from 'ee/security_dashboard/index';

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelector('#js-group-security-dashboard')) {
    initSecurityDashboard();
  } else {
    initGroupDetails();
  }
});

import initGroupSecurityDashboard from 'ee/security_dashboard/group_init';
import leaveByUrl from '~/namespaces/leave_by_url';
import initGroupDetails from '~/pages/groups/shared/group_details';
import initGroupAnalytics from 'ee/analytics/group_analytics/group_analytics_bundle';
import initVueAlerts from '~/vue_alerts';

document.addEventListener('DOMContentLoaded', () => {
  leaveByUrl('group');

  if (document.querySelector('#js-group-security-dashboard')) {
    initGroupSecurityDashboard();
  } else {
    initGroupDetails();
  }

  initGroupAnalytics();
  initVueAlerts();
});

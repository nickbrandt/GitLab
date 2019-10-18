import initInstanceSecurityDashboard from 'ee/security_dashboard/instance_init';

if (gon.features?.instanceSecurityDashboard) {
  document.addEventListener('DOMContentLoaded', initInstanceSecurityDashboard);
}

import '~/pages/projects/settings/ci_cd/show/index';
import ProtectedEnvironmentCreate from 'ee/protected_environments/protected_environment_create';

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new ProtectedEnvironmentCreate();
});

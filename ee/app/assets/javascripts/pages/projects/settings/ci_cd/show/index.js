import '~/pages/projects/settings/ci_cd/show/index';
import ProtectedEnvironmentCreate from 'ee/protected_environments/protected_environment_create';
import ProtectedEnvironmentEditList from 'ee/protected_environments/protected_environment_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new ProtectedEnvironmentCreate();

  // eslint-disable-next-line no-new
  new ProtectedEnvironmentEditList();
});

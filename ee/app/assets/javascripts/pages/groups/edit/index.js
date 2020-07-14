import '~/pages/groups/edit';
import initAccessRestrictionField from 'ee/groups/settings/access_restriction_field';
import { __ } from '~/locale';

document.addEventListener('DOMContentLoaded', () => {
  initAccessRestrictionField('.js-allowed-email-domains', __('Enter domain'));
  initAccessRestrictionField(
    '.js-ip-restriction',
    __('Enter IP address range'),
    'ip_restriction_field',
  );
});

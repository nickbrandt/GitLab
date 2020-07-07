import '~/pages/groups/edit';
import initAllowedEmailDomains from 'ee/groups/settings/allowed_email_domains';

document.addEventListener('DOMContentLoaded', () => {
  initAllowedEmailDomains();
});

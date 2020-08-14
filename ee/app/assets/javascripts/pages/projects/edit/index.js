/* eslint-disable no-new */

import '~/pages/projects/edit';
import mountApprovals from 'ee/approvals/mount_project_settings';
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import groupsSelect from '~/groups_select';
import initProjectAdjournedDeleteButton from 'ee/projects/project_adjourned_delete_button';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect();
  groupsSelect();

  new UserCallout({ className: 'js-mr-approval-callout' });

  mountApprovals(document.getElementById('js-mr-approvals-settings'));

  initProjectAdjournedDeleteButton();
});

/* eslint-disable no-new */

import mountApprovals from 'ee/approvals/mount_project_settings';
import initMergeOptionSettings from 'ee/pages/projects/edit/merge_options';
import mountStatusChecks from 'ee/status_checks/mount';
import groupsSelect from '~/groups_select';
import UserCallout from '~/user_callout';
import UsersSelect from '~/users_select';

new UsersSelect();
groupsSelect();

new UserCallout({ className: 'js-mr-approval-callout' });

mountApprovals(document.getElementById('js-mr-approvals-settings'));
mountStatusChecks(document.getElementById('js-status-checks-settings'));

initMergeOptionSettings();

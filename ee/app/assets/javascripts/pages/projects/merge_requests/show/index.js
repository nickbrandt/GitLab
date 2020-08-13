import initSidebarBundle from 'ee/sidebar/sidebar_bundle';
import { initReviewBar } from '~/batch_comments';
import initMrNotes from '~/mr_notes';
import store from '~/mr_notes/stores';
import initIssuableHeaderWarning from '~/vue_shared/components/issuable/init_issuable_header_warning';
import initShow from '~/pages/projects/merge_requests/init_merge_request_show';
import trackShowInviteMemberLink from 'ee/projects/track_invite_members';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  if (gon.features && !gon.features.vueIssuableSidebar) {
    initSidebarBundle();
  }
  initMrNotes();
  initReviewBar();
  initIssuableHeaderWarning(store);

  const assigneeDropdown = document.querySelector('.js-sidebar-assignee-dropdown');

  if (assigneeDropdown) trackShowInviteMemberLink(assigneeDropdown);
});

import initSidebarBundle from 'ee/sidebar/sidebar_bundle';
import { initReviewBar } from '~/batch_comments';
import initMrNotes from '~/mr_notes';
import initShow from '~/pages/projects/merge_requests/init_merge_request_show';
import trackShowInviteMemberLink from 'ee/projects/track_invite_members';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  if (gon.features && !gon.features.vueIssuableSidebar) {
    initSidebarBundle();
  }
  initMrNotes();
  initReviewBar();

  const assigneeDropdown = document.querySelector('.js-sidebar-assignee-dropdown');

  if (assigneeDropdown) trackShowInviteMemberLink(assigneeDropdown);
});

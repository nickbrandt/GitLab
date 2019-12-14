import initSidebarBundle from 'ee/sidebar/sidebar_bundle';
import { initReviewBar } from 'ee/batch_comments';
import initMrNotes from '~/mr_notes';
import initShow from '~/pages/projects/merge_requests/init_merge_request_show';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  if (gon.features && !gon.features.vueIssuableSidebar) {
    initSidebarBundle();
  }
  initMrNotes();
  initReviewBar();
});

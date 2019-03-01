import Vue from 'vue';
import initNotesApp from 'ee_else_ce/mr_notes/init_notes';
import initDiffsApp from '../diffs';
import discussionCounter from '../notes/components/discussion_counter.vue';
import initDiscussionFilters from '../notes/discussion_filters';
import store from './stores';
import MergeRequest from '../merge_request';
import { resetServiceWorkersPublicPath } from '../lib/utils/webpack';

export default function initMrNotes() {
  resetServiceWorkersPublicPath();

  const mrShowNode = document.querySelector('.merge-request');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrShowNode.dataset.mrAction,
  });

  initNotesApp();

  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-discussion-counter',
    name: 'DiscussionCounter',
    components: {
      discussionCounter,
    },
    store,
    render(createElement) {
      return createElement('discussion-counter');
    },
  });

  initDiscussionFilters(store);
  initDiffsApp(store);
}

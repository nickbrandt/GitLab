import Vue from 'vue';
import * as types from './mutation_types';

export default {
  [types.SET_DISCUSSIONS_DICTIONARY](state, discussionsDictionary) {
    state.discussionsDictionary = discussionsDictionary;
  },

  [types.UPDATE_DISCUSSION](state, { id, updatedDiscussion }) {
    Vue.set(state.discussionsDictionary, id, updatedDiscussion);
  },

  [types.SET_POLL](state, poll) {
    state.poll = poll;
  },

  [types.SET_LAST_FETCHED_AT](state, lastFetchedAt) {
    state.lastFetchedAt = lastFetchedAt;
  },
};

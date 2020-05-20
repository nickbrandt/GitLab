import Visibility from 'visibilityjs';
import { keyBy } from 'lodash';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import { __, s__ } from '~/locale';
import { dateToSeconds } from './utils';
import * as types from './mutation_types';

export const setDiscussionsDictionary = ({ commit }, discussionsDictionary) =>
  commit(types.SET_DISCUSSIONS_DICTIONARY, discussionsDictionary);

export const updateDiscussion = ({ commit }, { id, updatedDiscussion }) =>
  commit(types.UPDATE_DISCUSSION, { id, updatedDiscussion });

export const setLastFetchedAt = ({ commit }, lastFetchedAt) =>
  commit(types.SET_LAST_FETCHED_AT, lastFetchedAt);

export const setPoll = ({ commit }, poll) => commit(types.SET_POLL, poll);

export const createNotesPoll = ({ state, dispatch }, notesUrl) => {
  const poll = new Poll({
    resource: {
      fetchNotes: () =>
        axios.get(notesUrl, { headers: { 'X-Last-Fetched-At': state.lastFetchedAt } }),
    },
    method: 'fetchNotes',
    successCallback: ({ data: { notes, last_fetched_at: lastFetchedAt } }) => {
      dispatch('updateNotes', notes);

      dispatch('setLastFetchedAt', lastFetchedAt);
    },
    errorCallback: () => {
      createFlash(__('Something went wrong while fetching latest comments.'));
    },
  });

  dispatch('setPoll', poll);
};

export const setupPolling = ({ state, dispatch }, notesUrl) => {
  if (!state.poll) dispatch('createNotesPoll', notesUrl);

  if (!Visibility.hidden()) {
    state.poll.makeRequest();
  }

  Visibility.change(() => {
    if (Visibility.hidden()) {
      state.poll.stop();
    } else {
      state.poll.restart();
    }
  });
};

export const fetchDiscussions = ({ dispatch }, { discussionsUrl, notesUrl }) => {
  return axios
    .get(discussionsUrl)
    .then(({ data, headers: { date } }) => {
      const discussionsDictionary = keyBy(data, 'id');

      dispatch('setDiscussionsDictionary', discussionsDictionary);

      dispatch('setLastFetchedAt', dateToSeconds(date));

      dispatch('setupPolling', notesUrl);
    })
    .catch(() => {
      createFlash(
        s__(
          'VulnerabilityManagement|Something went wrong while trying to retrieve the vulnerability history. Please try again later.',
        ),
      );
    });
};

export const updateNotes = ({ state, dispatch }, notes) => {
  notes.forEach(note => {
    // If the note exists, update it.
    if (this.noteDictionary[note.id]) {
      const updatedDiscussion = { ...state.discussionsDictionary[note.discussion_id] };
      updatedDiscussion.notes = updatedDiscussion.notes.map(curr =>
        curr.id === note.id ? note : curr,
      );
      dispatch('updateDiscussion', { id: note.discussion_id, updatedDiscussion });
    }
    // If the note doesn't exist, but the discussion does, add the note to the discussion.
    else if (this.discussionsDictionary[note.discussion_id]) {
      const updatedDiscussion = { ...state.discussionsDictionary[note.discussion_id] };
      updatedDiscussion.notes.push(note);
      dispatch('updateDiscussion', { id: note.discussion_id, updatedDiscussion });
    }
    // If the discussion doesn't exist, create it.
    else {
      const newDiscussion = {
        id: note.discussion_id,
        reply_id: note.discussion_id,
        notes: [note],
      };
      dispatch('updateDiscussion', { id: note.discussion_id, newDiscussion });
    }
  });
};

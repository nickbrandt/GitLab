import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_MERGE_REQUEST](state, currentMergeRequestId) {
    Object.assign(state, {
      currentMergeRequestId,
    });
  },
  [types.SET_MERGE_REQUEST](state, { mergeRequestId, mergeRequest }) {
    const existingMergeRequest = state.project.mergeRequests[mergeRequestId] || {};

    Object.assign(state.project, {
      mergeRequests: {
        [mergeRequestId]: {
          ...mergeRequest,
          active: true,
          changes: [],
          versions: [],
          baseCommitSha: null,
          ...existingMergeRequest,
        },
      },
    });
  },
  [types.SET_MERGE_REQUEST_CHANGES](state, { mergeRequestId, changes }) {
    Object.assign(state.project.mergeRequests[mergeRequestId], {
      changes,
    });
  },
  [types.SET_MERGE_REQUEST_VERSIONS](state, { mergeRequestId, versions }) {
    Object.assign(state.project.mergeRequests[mergeRequestId], {
      versions,
      baseCommitSha: versions.length ? versions[0].base_commit_sha : null,
    });
  },
};

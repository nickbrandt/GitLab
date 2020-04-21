import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/code_review_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/code_review_analytics/store/modules/filters/mutation_types';
import getInitialState from 'ee/analytics/code_review_analytics/store/modules/filters/state';

describe('Code review analytics filters actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = getInitialState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setFilters', () => {
    const milestoneTitle = 'my milestone';
    const labelName = ['first label', 'second label'];

    it('commits the SET_FILTERS mutation', () => {
      testAction(
        actions.setFilters,
        { milestone_title: milestoneTitle, label_name: labelName },
        state,
        [
          {
            type: types.SET_FILTERS,
            payload: { milestoneTitle, labelName },
          },
        ],
        [
          { type: 'mergeRequests/setPage', payload: 1 },
          { type: 'mergeRequests/fetchMergeRequests', payload: null },
        ],
      );
    });
  });
});

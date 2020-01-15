import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/code_review_analytics/store/actions';
import * as types from 'ee/analytics/code_review_analytics/store/mutation_types';
import getInitialState from 'ee/analytics/code_review_analytics/store/state';
import createFlash from '~/flash';

jest.mock('~/flash', () => jest.fn());

describe('Code review analytics actions', () => {
  afterEach(() => {
    createFlash.mockClear();
  });

  describe('setProjectId', () => {
    it('commits the SET_PROJECT_ID mutation', () =>
      testAction(
        actions.setProjectId,
        1,
        getInitialState(),
        [
          {
            type: types.SET_PROJECT_ID,
            payload: 1,
          },
        ],
        [],
      ));
  });

  describe('setFilters', () => {
    const milestoneTitle = 'my milestone';
    const labelName = ['first label', 'second label'];

    it('commits the SET_FILTERS mutation', () => {
      testAction(
        actions.setFilters,
        { milestone_title: milestoneTitle, label_name: labelName },
        getInitialState(),
        [
          {
            type: types.SET_FILTERS,
            payload: { milestoneTitle, labelName },
          },
        ],
        [],
      );
    });
  });
});

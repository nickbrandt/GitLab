import * as types from 'ee/analytics/code_review_analytics/store/mutation_types';
import mutations from 'ee/analytics/code_review_analytics/store/mutations';
import getInitialState from 'ee/analytics/code_review_analytics/store/state';

describe('Code review analytics mutations', () => {
  let state;

  const milestoneTitle = 'my milestone';
  const labelName = ['first label', 'second label'];

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_PROJECT_ID, () => {
    it('sets the project id', () => {
      mutations[types.SET_PROJECT_ID](state, 1);

      expect(state.projectId).toBe(1);
    });
  });

  describe(types.SET_FILTERS, () => {
    it('updates milestoneTitle and labelName', () => {
      mutations[types.SET_FILTERS](state, { milestoneTitle, labelName });

      expect(state.filters.milestoneTitle).toBe(milestoneTitle);
      expect(state.filters.labelName).toBe(labelName);
    });
  });
});

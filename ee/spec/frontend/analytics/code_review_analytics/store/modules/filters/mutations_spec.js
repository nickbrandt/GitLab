import * as types from 'ee/analytics/code_review_analytics/store/modules/filters/mutation_types';
import mutations from 'ee/analytics/code_review_analytics/store/modules/filters/mutations';
import getInitialState from 'ee/analytics/code_review_analytics/store/modules/filters/state';

describe('Code review analytics filters mutations', () => {
  let state;

  const milestoneTitle = 'my milestone';
  const labelName = ['first label', 'second label'];

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_FILTERS, () => {
    it('updates milestoneTitle and labelName', () => {
      mutations[types.SET_FILTERS](state, { milestoneTitle, labelName });

      expect(state.milestoneTitle).toBe(milestoneTitle);
      expect(state.labelName).toBe(labelName);
    });
  });
});

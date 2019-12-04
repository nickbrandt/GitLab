import * as types from 'ee/analytics/productivity_analytics/store/modules/filters/mutation_types';
import mutations from 'ee/analytics/productivity_analytics/store/modules/filters/mutations';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/filters/state';

describe('Productivity analytics filter mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_GROUP_NAMESPACE, () => {
    it('sets the groupNamespace', () => {
      const groupNamespace = 'gitlab-org';
      mutations[types.SET_GROUP_NAMESPACE](state, groupNamespace);

      expect(state.groupNamespace).toBe(groupNamespace);
    });
  });

  describe(types.SET_PROJECT_PATH, () => {
    it('sets the projectPath', () => {
      const projectPath = 'gitlab-org/gitlab-test';
      mutations[types.SET_PROJECT_PATH](state, projectPath);

      expect(state.projectPath).toBe(projectPath);
    });
  });

  describe(types.SET_FILTERS, () => {
    it('sets the authorUsername, milestoneTitle and labelName', () => {
      const authorUsername = 'root';
      const labelName = ['my label', 'yet another label'];
      const milestoneTitle = 'my milestone';
      mutations[types.SET_FILTERS](state, { authorUsername, labelName, milestoneTitle });

      expect(state.authorUsername).toBe(authorUsername);
      expect(state.labelName).toBe(labelName);
      expect(state.milestoneTitle).toBe(milestoneTitle);
    });
  });

  describe(types.SET_DATE_RANGE, () => {
    it('sets the startDate and endDate', () => {
      const currentYear = new Date().getFullYear();
      const startDate = new Date(currentYear, 8, 1);
      const endDate = new Date(currentYear, 8, 7);
      mutations[types.SET_DATE_RANGE](state, { startDate, endDate });

      expect(state.startDate).toBe(startDate);
      expect(state.endDate).toBe(endDate);
    });
  });
});

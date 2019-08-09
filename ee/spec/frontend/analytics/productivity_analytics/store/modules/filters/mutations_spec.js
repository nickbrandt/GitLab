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
      const projectPath = 'gitlab-test';
      mutations[types.SET_PROJECT_PATH](state, projectPath);

      expect(state.projectPath).toBe(projectPath);
    });
  });

  describe(types.SET_PATH, () => {
    it('sets the filters string', () => {
      const path = '?author_username=root&milestone_title=foo&label_name[]=labelxyz';
      mutations[types.SET_PATH](state, path);

      expect(state.filters).toBe(path);
    });
  });

  describe(types.SET_DAYS_IN_PAST, () => {
    it('sets the daysInPast', () => {
      const daysInPast = 14;
      mutations[types.SET_DAYS_IN_PAST](state, daysInPast);

      expect(state.daysInPast).toBe(daysInPast);
    });
  });
});

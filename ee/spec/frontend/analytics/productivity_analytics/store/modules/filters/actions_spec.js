import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/filters/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/filters/state';

describe('Productivity analytics filter actions', () => {
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-test';

  describe('setGroupNamespace', () => {
    it('commits the SET_GROUP_NAMESPACE mutation', done =>
      testAction(
        actions.setGroupNamespace,
        groupNamespace,
        getInitialState(),
        [
          {
            type: types.SET_GROUP_NAMESPACE,
            payload: groupNamespace,
          },
        ],
        [
          {
            type: 'charts/fetchAllChartData',
            payload: null,
          },
          {
            type: 'table/fetchMergeRequests',
            payload: null,
          },
        ],
        done,
      ));
  });

  describe('setProjectPath', () => {
    it('commits the SET_PROJECT_PATH mutation', done =>
      testAction(
        actions.setProjectPath,
        projectPath,
        getInitialState(),
        [
          {
            type: types.SET_PROJECT_PATH,
            payload: projectPath,
          },
        ],
        [
          {
            type: 'charts/fetchAllChartData',
            payload: null,
          },
          {
            type: 'table/fetchMergeRequests',
            payload: null,
          },
        ],
        done,
      ));
  });

  describe('setPath', () => {
    it('commits the SET_PATH mutation', done =>
      testAction(
        actions.setPath,
        'author_username=root',
        getInitialState(),
        [
          {
            type: types.SET_PATH,
            payload: 'author_username=root',
          },
        ],
        [
          {
            type: 'charts/fetchAllChartData',
            payload: null,
          },
          {
            type: 'table/fetchMergeRequests',
            payload: null,
          },
        ],
        done,
      ));
  });

  describe('setDaysInPast', () => {
    it('commits the SET_DAYS_IN_PAST mutation', done =>
      testAction(
        actions.setDaysInPast,
        90,
        getInitialState(),
        [
          {
            type: types.SET_DAYS_IN_PAST,
            payload: 90,
          },
        ],
        [
          {
            type: 'charts/fetchAllChartData',
            payload: null,
          },
          {
            type: 'table/fetchMergeRequests',
            payload: null,
          },
        ],
        done,
      ));
  });
});

import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/filters/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/filters/state';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/url_utility');

describe('Productivity analytics filter actions', () => {
  let store;
  const currentYear = new Date().getFullYear();
  const startDate = new Date(currentYear, 8, 1);
  const endDate = new Date(currentYear, 8, 7);
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';
  const initialData = {
    mergedAtAfter: new Date('2019-11-01'),
    mergedAtBefore: new Date('2019-12-09'),
    minDate: new Date('2019-01-01'),
  };

  beforeEach(() => {
    store = {
      commit: jest.fn(),
      dispatch: jest.fn(() => Promise.resolve()),
      state: {
        groupNamespace,
      },
    };
  });

  afterEach(() => {
    setUrlParams.mockClear();
  });

  describe('setInitialData', () => {
    it('commits the SET_INITIAL_DATA mutation and fetches data by default', done => {
      actions
        .setInitialData(store, { data: initialData })
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_INITIAL_DATA, initialData);

          expect(store.dispatch.mock.calls[0]).toEqual([
            'charts/fetchChartData',
            chartKeys.main,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[1]).toEqual([
            'charts/fetchSecondaryChartData',
            null,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[2]).toEqual(['table/setPage', 0, { root: true }]);
        })
        .then(done)
        .catch(done.fail);
    });

    it("commits the SET_INITIAL_DATA mutation and doesn't fetch data when skipFetch=true", done =>
      testAction(
        actions.setInitialData,
        { skipFetch: true, data: initialData },
        getInitialState(),
        [
          {
            type: types.SET_INITIAL_DATA,
            payload: initialData,
          },
        ],
        [],
        done,
      ));
  });

  describe('setGroupNamespace', () => {
    it('commits the SET_GROUP_NAMESPACE mutation', done => {
      actions
        .setGroupNamespace(store, groupNamespace)
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_GROUP_NAMESPACE, groupNamespace);

          expect(store.dispatch.mock.calls[0]).toEqual([
            'charts/resetMainChartSelection',
            true,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[1]).toEqual([
            'charts/fetchChartData',
            chartKeys.main,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[2]).toEqual([
            'charts/fetchSecondaryChartData',
            null,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls setUrlParams with the group_id param', done => {
      actions
        .setGroupNamespace(store, groupNamespace)
        .then(() => {
          expect(setUrlParams).toHaveBeenCalledWith(
            { group_id: groupNamespace },
            window.location.href,
            true,
          );
          expect(historyPushState).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setProjectPath', () => {
    it('commits the SET_PROJECT_PATH mutation', done => {
      actions
        .setProjectPath(store, projectPath)
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_PROJECT_PATH, projectPath);

          expect(store.dispatch.mock.calls[0]).toEqual([
            'charts/resetMainChartSelection',
            true,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[1]).toEqual([
            'charts/fetchChartData',
            chartKeys.main,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[2]).toEqual([
            'charts/fetchSecondaryChartData',
            null,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls setUrlParams with the group_id and project_id params', done => {
      actions
        .setProjectPath(store, projectPath)
        .then(() => {
          expect(setUrlParams).toHaveBeenCalledWith(
            { group_id: groupNamespace, project_id: projectPath },
            window.location.href,
            true,
          );
          expect(historyPushState).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setFilters', () => {
    it('commits the SET_FILTERS mutation', done => {
      actions
        .setFilters(store, { author_username: 'root' })
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_FILTERS, { authorUsername: 'root' });

          expect(store.dispatch.mock.calls[0]).toEqual([
            'charts/resetMainChartSelection',
            true,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[1]).toEqual([
            'charts/fetchChartData',
            chartKeys.main,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[2]).toEqual([
            'charts/fetchSecondaryChartData',
            null,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls setUrlParams with the author_username', done => {
      actions
        .setFilters(store, { author_username: 'root' })
        .then(() => {
          expect(setUrlParams).toHaveBeenCalledWith({ author_username: 'root' });
          expect(historyPushState).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setDateRange', () => {
    it('commits the SET_DATE_RANGE mutation', done => {
      actions
        .setDateRange(store, { startDate, endDate })
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_DATE_RANGE, { startDate, endDate });

          expect(store.dispatch.mock.calls[0]).toEqual([
            'charts/resetMainChartSelection',
            true,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[1]).toEqual([
            'charts/fetchChartData',
            chartKeys.main,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[2]).toEqual([
            'charts/fetchSecondaryChartData',
            null,
            { root: true },
          ]);

          expect(store.dispatch.mock.calls[3]).toEqual(['table/setPage', 0, { root: true }]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls setUrlParams with the merged_at_after=startDate and merged_at_before=endDate', done => {
      actions
        .setDateRange(store, { startDate, endDate })
        .then(() => {
          expect(setUrlParams).toHaveBeenCalledWith({
            merged_at_after: startDate,
            merged_at_before: endDate,
          });

          expect(historyPushState).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});

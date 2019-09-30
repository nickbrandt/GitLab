import * as actions from 'ee/analytics/productivity_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/filters/mutation_types';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';

describe('Productivity analytics filter actions', () => {
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';
  const path = 'author_username=root';
  const daysInPast = 90;

  describe('setGroupNamespace', () => {
    it('commits the SET_GROUP_NAMESPACE mutation', done => {
      const store = {
        commit: jest.fn(),
        dispatch: jest.fn(() => Promise.resolve()),
      };

      actions
        .setGroupNamespace(store, groupNamespace)
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_GROUP_NAMESPACE, groupNamespace);

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
  });

  describe('setProjectPath', () => {
    it('commits the SET_PROJECT_PATH mutation', done => {
      const store = {
        commit: jest.fn(),
        dispatch: jest.fn(() => Promise.resolve()),
      };

      actions
        .setProjectPath(store, projectPath)
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_PROJECT_PATH, projectPath);

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
  });

  describe('setPath', () => {
    it('commits the SET_PATH mutation', done => {
      const store = {
        commit: jest.fn(),
        dispatch: jest.fn(() => Promise.resolve()),
      };

      actions
        .setPath(store, path)
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_PATH, path);

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
  });

  describe('setDaysInPast', () => {
    it('commits the SET_DAYS_IN_PAST mutation', done => {
      const store = {
        commit: jest.fn(),
        dispatch: jest.fn(() => Promise.resolve()),
      };

      actions
        .setDaysInPast(store, daysInPast)
        .then(() => {
          expect(store.commit).toHaveBeenCalledWith(types.SET_DAYS_IN_PAST, daysInPast);

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
  });
});

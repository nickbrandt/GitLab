import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import * as actions from 'ee/issues_analytics/stores/modules/issue_analytics/actions';
import axios from '~/lib/utils/axios_utils';

describe('Issue analytics store actions', () => {
  describe('setFilters', () => {
    it('commits SET_FILTERS', done => {
      testAction(
        actions.setFilters,
        null,
        null,
        [{ type: 'SET_FILTERS', payload: null }],
        [],
        done,
      );
    });
  });

  describe('setLoadingState', () => {
    it('commits SET_LOADING_STATE', done => {
      testAction(
        actions.setLoadingState,
        true,
        null,
        [{ type: 'SET_LOADING_STATE', payload: true }],
        [],
        done,
      );
    });
  });

  describe('fetchChartData', () => {
    let mock;
    let commit;
    let dispatch;
    const chartData = { '2017-11': 0, '2017-12': 2 };

    beforeEach(() => {
      dispatch = jasmine.createSpy('dispatch');
      commit = jasmine.createSpy('commit');
      mock = new MockAdapter(axios);

      mock.onGet().reply(200, chartData);
    });

    afterEach(() => {
      mock.restore();
    });

    it('commits SET_CHART_DATA with chart data', done => {
      const getters = { appliedFilters: '?hello=world' };
      const context = {
        dispatch,
        getters,
        commit,
      };

      actions
        .fetchChartData(context, gl.TEST_HOST)
        .then(() => {
          expect(dispatch.calls.argsFor(0)).toEqual(['setLoadingState', true]);
          expect(commit).toHaveBeenCalledWith('SET_CHART_DATA', chartData);
          expect(dispatch.calls.argsFor(1)).toEqual(['setLoadingState', false]);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});

import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import * as actions from 'ee/insights/stores/modules/insights/actions';
import store from 'ee/insights/stores/';

describe('Insights store actions', () => {
  const key = 'bugsPerTeam';
  const chart = {
    title: 'Bugs Per Team',
    type: 'stacked-bar',
    query: {
      name: 'filter_issues_by_label_category',
      filter_label: 'bug',
      category_labels: ['Plan', 'Create', 'Manage'],
    },
  };
  const configData = {};

  beforeEach(() => {
    configData[key] = chart;
  });

  describe('requestConfig', () => {
    it('commits REQUEST_CONFIG', done => {
      testAction(actions.requestConfig, null, null, [{ type: 'REQUEST_CONFIG' }], [], done);
    });
  });

  describe('receiveConfigSuccess', () => {
    it('commits RECEIVE_CONFIG_SUCCESS', done => {
      testAction(
        actions.receiveConfigSuccess,
        [{ chart: 'chart' }],
        null,
        [{ type: 'RECEIVE_CONFIG_SUCCESS', payload: [{ chart: 'chart' }] }],
        [],
        done,
      );
    });
  });

  describe('receiveConfigError', () => {
    it('commits RECEIVE_CONFIG_ERROR', done => {
      testAction(
        actions.receiveConfigError,
        null,
        null,
        [{ type: 'RECEIVE_CONFIG_ERROR' }],
        [],
        done,
      );
    });
  });

  describe('fetchConfigData', () => {
    let mock;
    let dispatch;

    beforeEach(() => {
      dispatch = jasmine.createSpy('dispatch');
      mock = new MockAdapter(axios);

      mock.onGet(gl.TEST_HOST).reply(200, configData);
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls requestConfig', done => {
      const context = {
        dispatch,
      };

      actions
        .fetchConfigData(context, gl.TEST_HOST)
        .then(() => {
          expect(dispatch.calls.argsFor(0)).toEqual(['requestConfig']);
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls receiveConfigSuccess with config data', done => {
      const context = {
        dispatch,
      };

      actions
        .fetchConfigData(context, gl.TEST_HOST)
        .then(() => {
          expect(dispatch.calls.argsFor(1)).toEqual(['receiveConfigSuccess', configData]);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestChartData', () => {
    it('commits REQUEST_CHART', done => {
      testAction(actions.requestChartData, null, null, [{ type: 'REQUEST_CHART' }], [], done);
    });
  });

  describe('receiveChartDataSuccess', () => {
    it('commits RECEIVE_CHART_SUCCESS', done => {
      testAction(
        actions.receiveChartDataSuccess,
        { type: 'bar', data: {} },
        null,
        [{ type: 'RECEIVE_CHART_SUCCESS', payload: { type: 'bar', data: {} } }],
        [],
        done,
      );
    });
  });

  describe('receiveChartDataError', () => {
    it('commits RECEIVE_CHART_ERROR', done => {
      testAction(
        actions.receiveChartDataError,
        null,
        null,
        [{ type: 'RECEIVE_CHART_ERROR' }],
        [],
        done,
      );
    });
  });

  describe('fetchChartData', () => {
    let mock;
    let dispatch;
    let state;
    const chartData = {
      labels: ['January'],
      datasets: [
        {
          label: 'Dataset 1',
          fill: true,
          backgroundColor: ['rgba(255, 99, 132)'],
          data: [1],
        },
        {
          label: 'Dataset 2',
          fill: true,
          backgroundColor: ['rgba(54, 162, 235)'],
          data: [2],
        },
      ],
    };

    beforeEach(() => {
      store.state.insights.activeChart = chart;

      state = store.state.insights;
      dispatch = jasmine.createSpy('dispatch');
      mock = new MockAdapter(axios);

      mock
        .onPost(`${gl.TEST_HOST}/query`, {
          query: chart.query,
          chart_type: chart.type,
        })
        .reply(200, chartData);
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls requestChartData', done => {
      const context = {
        dispatch,
        state,
      };

      actions
        .fetchChartData(context, `${gl.TEST_HOST}/query`)
        .then(() => {
          expect(dispatch.calls.argsFor(0)).toEqual(['requestChartData']);
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls receiveChartDataSuccess with chart data', done => {
      const context = {
        dispatch,
        state,
      };

      actions
        .fetchChartData(context, `${gl.TEST_HOST}/query`)
        .then(() => {
          expect(dispatch.calls.argsFor(1)).toEqual(['receiveChartDataSuccess', chartData]);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setActiveTab', () => {
    it('commits SET_ACTIVE_TAB and SET_ACTIVE_CHART', done => {
      const state = { configData };

      testAction(
        actions.setActiveTab,
        key,
        state,
        [{ type: 'SET_ACTIVE_TAB', payload: key }, { type: 'SET_ACTIVE_CHART', payload: chart }],
        [],
        done,
      );
    });
  });
});

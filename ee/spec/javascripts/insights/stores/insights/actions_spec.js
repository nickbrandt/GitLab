import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import actionsModule, * as actions from 'ee/insights/stores/modules/insights/actions';
import axios from '~/lib/utils/axios_utils';

const ERROR_MESSAGE = 'TEST_ERROR_MESSAGE';

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
  const page = {
    title: 'Bugs Charts',
    charts: [chart],
  };
  const configData = {};

  beforeEach(() => {
    configData[key] = page;
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
        [configData],
        null,
        [{ type: 'RECEIVE_CONFIG_SUCCESS', payload: [configData] }],
        [],
        done,
      );
    });
  });

  describe('receiveConfigError', () => {
    let flashSpy;

    beforeEach(() => {
      flashSpy = spyOnDependency(actionsModule, 'createFlash');
    });

    it('commits RECEIVE_CONFIG_ERROR and shows flash message', done => {
      testAction(
        actions.receiveConfigError,
        ERROR_MESSAGE,
        null,
        [{ type: 'RECEIVE_CONFIG_ERROR' }],
        [],
        () => {
          expect(flashSpy).toHaveBeenCalledWith(
            `There was an error fetching configuration for charts: ${ERROR_MESSAGE}`,
          );
          done();
        },
      );
    });

    it('flashes Unknown Error when error message is falsey', done => {
      testAction(
        actions.receiveConfigError,
        null,
        null,
        jasmine.any(Array),
        jasmine.any(Array),
        () => {
          expect(flashSpy).toHaveBeenCalledWith(
            `There was an error fetching configuration for charts: Unknown Error`,
          );
          done();
        },
      );
    });
  });

  describe('fetchConfigData', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success calls', () => {
      beforeEach(() => {
        mock.onGet(gl.TEST_HOST).reply(200, configData);
      });

      it('calls requestConfig and receiveConfigSuccess', done => {
        testAction(
          actions.fetchConfigData,
          gl.TEST_HOST,
          {},
          [],
          [{ type: 'requestConfig' }, { type: 'receiveConfigSuccess', payload: configData }],
          done,
        );
      });
    });

    describe('failed calls', () => {
      beforeEach(() => {
        mock.onGet(gl.TEST_HOST).reply(500, { message: ERROR_MESSAGE });
      });

      it('calls receiveConfigError upon error from service', done => {
        testAction(
          actions.fetchConfigData,
          gl.TEST_HOST,
          {},
          [],
          [{ type: 'requestConfig' }, { type: 'receiveConfigError', payload: ERROR_MESSAGE }],
          done,
        );
      });
    });

    describe('success calls with null data', () => {
      beforeEach(() => {
        mock.onGet(gl.TEST_HOST).reply(200, null);
      });

      it('calls receiveConfigError upon null config data returned', done => {
        testAction(
          actions.fetchConfigData,
          gl.TEST_HOST,
          {},
          [],
          [{ type: 'requestConfig' }, { type: 'receiveConfigError' }],
          done,
        );
      });
    });
  });

  describe('receiveChartDataSuccess', () => {
    const chartData = { type: 'bar', data: {} };

    it('commits RECEIVE_CHART_SUCCESS', done => {
      testAction(
        actions.receiveChartDataSuccess,
        { chart, data: chartData },
        null,
        [
          {
            type: 'RECEIVE_CHART_SUCCESS',
            payload: { chart, data: chartData },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveChartDataError', () => {
    const error = 'myError';

    it('commits RECEIVE_CHART_ERROR', done => {
      testAction(
        actions.receiveChartDataError,
        { chart, error },
        null,
        [
          {
            type: 'RECEIVE_CHART_ERROR',
            payload: { chart, error },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchChartData', () => {
    let mock;
    let dispatch;
    const payload = { endpoint: `${gl.TEST_HOST}/query`, chart };

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
      dispatch = jasmine.createSpy('dispatch');
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('successful request', () => {
      beforeEach(() => {
        mock.onPost(`${gl.TEST_HOST}/query`, chart).reply(200, chartData);
      });

      it('calls receiveChartDataSuccess with chart data', done => {
        const context = {
          dispatch,
        };

        actions
          .fetchChartData(context, payload)
          .then(() => {
            expect(dispatch.calls.argsFor(0)).toEqual([
              'receiveChartDataSuccess',
              { chart, data: chartData },
            ]);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('failed request', () => {
      beforeEach(() => {
        mock.onPost(`${gl.TEST_HOST}/query`, chart).reply(500);
      });

      it('calls receiveChartDataError with error message', done => {
        const context = {
          dispatch,
        };

        actions
          .fetchChartData(context, payload)
          .then(() => {
            expect(dispatch.calls.argsFor(0)).toEqual([
              'receiveChartDataError',
              { chart, error: 'There was an error gathering the chart data' },
            ]);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('setActiveTab', () => {
    let state;

    beforeEach(() => {
      state = { configData };
    });

    it('commits SET_ACTIVE_TAB and SET_ACTIVE_PAGE', done => {
      testAction(
        actions.setActiveTab,
        key,
        state,
        [{ type: 'SET_ACTIVE_TAB', payload: key }, { type: 'SET_ACTIVE_PAGE', payload: page }],
        [],
        done,
      );
    });

    it('does not mutate with no configData', done => {
      state = { configData: null };

      testAction(actions.setActiveTab, key, state, [], [], done);
    });

    it('does not mutate with no matching tab', done => {
      testAction(actions.setActiveTab, 'invalidTab', state, [], [], done);
    });
  });

  describe('initChartData', () => {
    it('commits INIT_CHART_DATA', done => {
      const keys = ['a', 'b'];

      testAction(
        actions.initChartData,
        keys,
        null,
        [{ type: 'INIT_CHART_DATA', payload: keys }],
        [],
        done,
      );
    });
  });

  describe('setPageLoading', () => {
    it('commits SET_PAGE_LOADING', done => {
      const pageLoading = false;

      testAction(
        actions.setPageLoading,
        pageLoading,
        null,
        [{ type: 'SET_PAGE_LOADING', payload: false }],
        [],
        done,
      );
    });
  });
});

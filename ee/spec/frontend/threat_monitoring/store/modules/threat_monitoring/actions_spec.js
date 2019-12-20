import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import testAction from 'helpers/vuex_action_helper';

import * as actions from 'ee/threat_monitoring/store/modules/threat_monitoring/actions';
import * as types from 'ee/threat_monitoring/store/modules/threat_monitoring/mutation_types';
import getInitialState from 'ee/threat_monitoring/store/modules/threat_monitoring/state';

import { mockEnvironmentsResponse, mockWafStatisticsResponse } from '../../../mock_data';

jest.mock('~/flash', () => jest.fn());

const environmentsEndpoint = 'environmentsEndpoint';
const wafStatisticsEndpoint = 'wafStatisticsEndpoint';

describe('Threat Monitoring actions', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  afterEach(() => {
    createFlash.mockClear();
  });

  describe('setEndpoints', () => {
    it('commits the SET_ENDPOINTS mutation', () =>
      testAction(
        actions.setEndpoints,
        { environmentsEndpoint, wafStatisticsEndpoint },
        state,
        [
          {
            type: types.SET_ENDPOINTS,
            payload: { environmentsEndpoint, wafStatisticsEndpoint },
          },
        ],
        [],
      ));
  });

  describe('requestEnvironments', () => {
    it('commits the REQUEST_ENVIRONMENTS mutation', () =>
      testAction(
        actions.requestEnvironments,
        undefined,
        state,
        [
          {
            type: types.REQUEST_ENVIRONMENTS,
          },
        ],
        [],
      ));
  });

  describe('receiveEnvironmentsSuccess', () => {
    const environments = [{ id: 1, name: 'production' }];

    it('commits the RECEIVE_ENVIRONMENTS_SUCCESS mutation', () =>
      testAction(
        actions.receiveEnvironmentsSuccess,
        environments,
        state,
        [
          {
            type: types.RECEIVE_ENVIRONMENTS_SUCCESS,
            payload: environments,
          },
        ],
        [],
      ));
  });

  describe('receiveEnvironmentsError', () => {
    it('commits the RECEIVE_ENVIRONMENTS_ERROR mutation', () =>
      testAction(
        actions.receiveEnvironmentsError,
        undefined,
        state,
        [
          {
            type: types.RECEIVE_ENVIRONMENTS_ERROR,
          },
        ],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalled();
      }));
  });

  describe('fetchEnvironments', () => {
    let mock;

    beforeEach(() => {
      state.environmentsEndpoint = environmentsEndpoint;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onGet(environmentsEndpoint).replyOnce(200, mockEnvironmentsResponse);
      });

      it('should dispatch the request and success actions', () =>
        testAction(
          actions.fetchEnvironments,
          undefined,
          state,
          [],
          [
            { type: 'requestEnvironments' },
            {
              type: 'receiveEnvironmentsSuccess',
              payload: mockEnvironmentsResponse.environments,
            },
          ],
        ));
    });

    describe('given more than one page of environments', () => {
      beforeEach(() => {
        const oneEnvironmentPerPage = ({ totalPages }) => config => {
          const { page } = config.params;
          const response = [200, { environments: [{ id: page }] }];
          if (page < totalPages) {
            response.push({ 'x-next-page': page + 1 });
          }
          return response;
        };

        mock.onGet(environmentsEndpoint).reply(oneEnvironmentPerPage({ totalPages: 3 }));
      });

      it('should fetch all pages and dispatch the request and success actions', () =>
        testAction(
          actions.fetchEnvironments,
          undefined,
          state,
          [],
          [
            { type: 'requestEnvironments' },
            {
              type: 'receiveEnvironmentsSuccess',
              payload: [{ id: 1 }, { id: 2 }, { id: 3 }],
            },
          ],
        ));
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(environmentsEndpoint).replyOnce(500);
      });

      it('should dispatch the request and error actions', () =>
        testAction(
          actions.fetchEnvironments,
          undefined,
          state,
          [],
          [{ type: 'requestEnvironments' }, { type: 'receiveEnvironmentsError' }],
        ));
    });

    describe('with an empty endpoint', () => {
      beforeEach(() => {
        state.environmentsEndpoint = '';
      });

      it('should dispatch receiveEnvironmentsError', () =>
        testAction(
          actions.fetchEnvironments,
          undefined,
          state,
          [],
          [{ type: 'receiveEnvironmentsError' }],
        ));
    });
  });

  describe('setCurrentEnvironmentId', () => {
    const environmentId = 1;

    it('commits the SET_CURRENT_ENVIRONMENT_ID mutation and dispatches fetchWafStatistics', () =>
      testAction(
        actions.setCurrentEnvironmentId,
        environmentId,
        state,
        [{ type: types.SET_CURRENT_ENVIRONMENT_ID, payload: environmentId }],
        [{ type: 'fetchWafStatistics' }],
      ));
  });

  describe('requestWafStatistics', () => {
    it('commits the REQUEST_WAF_STATISTICS mutation', () =>
      testAction(
        actions.requestWafStatistics,
        undefined,
        state,
        [
          {
            type: types.REQUEST_WAF_STATISTICS,
          },
        ],
        [],
      ));
  });

  describe('receiveWafStatisticsSuccess', () => {
    it('commits the RECEIVE_WAF_STATISTICS_SUCCESS mutation', () =>
      testAction(
        actions.receiveWafStatisticsSuccess,
        mockWafStatisticsResponse,
        state,
        [
          {
            type: types.RECEIVE_WAF_STATISTICS_SUCCESS,
            payload: mockWafStatisticsResponse,
          },
        ],
        [],
      ));
  });

  describe('receiveWafStatisticsError', () => {
    it('commits the RECEIVE_WAF_STATISTICS_ERROR mutation', () =>
      testAction(
        actions.receiveWafStatisticsError,
        undefined,
        state,
        [
          {
            type: types.RECEIVE_WAF_STATISTICS_ERROR,
          },
        ],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalled();
      }));
  });

  describe('fetchWafStatistics', () => {
    let mock;
    const currentEnvironmentId = 3;

    beforeEach(() => {
      state.wafStatisticsEndpoint = wafStatisticsEndpoint;
      state.currentEnvironmentId = currentEnvironmentId;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(wafStatisticsEndpoint, { params: { environment_id: currentEnvironmentId } })
          .replyOnce(200, mockWafStatisticsResponse);
      });

      it('should dispatch the request and success actions', () =>
        testAction(
          actions.fetchWafStatistics,
          undefined,
          state,
          [],
          [
            { type: 'requestWafStatistics' },
            {
              type: 'receiveWafStatisticsSuccess',
              payload: mockWafStatisticsResponse,
            },
          ],
        ));
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(wafStatisticsEndpoint).replyOnce(500);
      });

      it('should dispatch the request and error actions', () =>
        testAction(
          actions.fetchWafStatistics,
          undefined,
          state,
          [],
          [{ type: 'requestWafStatistics' }, { type: 'receiveWafStatisticsError' }],
        ));
    });

    describe('with an empty endpoint', () => {
      beforeEach(() => {
        state.wafStatisticsEndpoint = '';
      });

      it('should dispatch receiveWafStatisticsError', () =>
        testAction(
          actions.fetchWafStatistics,
          undefined,
          state,
          [],
          [{ type: 'receiveWafStatisticsError' }],
        ));
    });
  });
});

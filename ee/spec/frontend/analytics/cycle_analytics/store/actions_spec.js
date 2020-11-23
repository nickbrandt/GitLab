import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/analytics/cycle_analytics/store/actions';
import * as stageActions from 'ee/analytics/cycle_analytics/store/modules/stages/actions';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  currentGroup,
  allowedStages as stages,
  startDate,
  endDate,
  customizableStagesAndEvents,
  endpoints,
  valueStreams,
} from '../mock_data';

const group = { fullPath: 'fake_group_full_path' };
const milestonesPath = 'fake_milestones_path';
const labelsPath = 'fake_labels_path';

const stageData = { events: [] };
const error = new Error(`Request failed with status code ${httpStatusCodes.NOT_FOUND}`);
const flashErrorMessage = 'There was an error while fetching value stream analytics data.';

stages[0].hidden = true;
const activeStages = stages.filter(({ hidden }) => !hidden);
const hiddenStage = stages[0];

const [selectedStage] = activeStages;
const selectedStageSlug = selectedStage.slug;
const [selectedValueStream] = valueStreams;

const mockGetters = {
  currentGroupPath: () => currentGroup.fullPath,
  currentValueStreamId: () => selectedValueStream.id,
};

const stageEndpoint = ({ stageId }) =>
  `/groups/${currentGroup.fullPath}/-/analytics/value_stream_analytics/value_streams/${selectedValueStream.id}/stages/${stageId}`;

jest.mock('~/flash');

describe('Value Stream Analytics actions', () => {
  let state;
  let mock;

  const shouldFlashAMessage = (msg, type = null) => {
    const args = type ? [msg, type] : [msg];
    expect(createFlash).toHaveBeenCalledWith(...args);
  };

  beforeEach(() => {
    state = {
      startDate,
      endDate,
      stages: [],
      featureFlags: {
        hasDurationChart: true,
      },
      activeStages,
      selectedValueStream,
      ...mockGetters,
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...state, currentGroup: null };
  });

  it.each`
    action                   | type                       | stateKey                | payload
    ${'setFeatureFlags'}     | ${'SET_FEATURE_FLAGS'}     | ${'featureFlags'}       | ${{ hasDurationChart: true }}
    ${'setSelectedProjects'} | ${'SET_SELECTED_PROJECTS'} | ${'selectedProjectIds'} | ${[10, 20, 30, 40]}
  `('$action should set $stateKey with $payload and type $type', ({ action, type, payload }) => {
    return testAction(
      actions[action],
      payload,
      state,
      [
        {
          type,
          payload,
        },
      ],
      [],
    );
  });

  describe('setSelectedValueStream', () => {
    const vs = { id: 'vs-1', name: 'Value stream 1' };

    it('refetches the cycle analytics data', () => {
      return testAction(
        actions.setSelectedValueStream,
        vs,
        { ...state, selectedValueStream: {} },
        [{ type: types.SET_SELECTED_VALUE_STREAM, payload: vs }],
        [{ type: 'fetchValueStreamData' }],
      );
    });
  });

  describe('setPaths', () => {
    it('dispatches the filters/setEndpoints action with enpoints', () => {
      return testAction(
        actions.setPaths,
        { groupPath: group.fullPath, milestonesPath, labelsPath },
        state,
        [],
        [
          {
            type: 'filters/setEndpoints',
            payload: {
              groupEndpoint: 'fake_group_full_path',
              labelsEndpoint: 'fake_labels_path.json',
              milestonesEndpoint: 'fake_milestones_path.json',
            },
          },
        ],
      );
    });
  });

  describe('setDateRange', () => {
    const payload = { startDate, endDate };

    it('dispatches the fetchCycleAnalyticsData action', () => {
      return testAction(
        actions.setDateRange,
        payload,
        state,
        [{ type: types.SET_DATE_RANGE, payload: { startDate, endDate } }],
        [{ type: 'fetchCycleAnalyticsData' }],
      );
    });
  });

  describe('fetchCycleAnalyticsData', () => {
    function mockFetchCycleAnalyticsAction(overrides = {}) {
      const mocks = {
        requestCycleAnalyticsData:
          overrides.requestCycleAnalyticsData || jest.fn().mockResolvedValue(),
        fetchStageMedianValues: overrides.fetchStageMedianValues || jest.fn().mockResolvedValue(),
        fetchGroupStagesAndEvents:
          overrides.fetchGroupStagesAndEvents || jest.fn().mockResolvedValue(),
        receiveCycleAnalyticsDataSuccess:
          overrides.receiveCycleAnalyticsDataSuccess || jest.fn().mockResolvedValue(),
      };
      return {
        mocks,
        mockDispatchContext: jest
          .fn()
          .mockImplementationOnce(mocks.requestCycleAnalyticsData)
          .mockImplementationOnce(mocks.fetchGroupStagesAndEvents)
          .mockImplementationOnce(mocks.fetchStageMedianValues)
          .mockImplementationOnce(mocks.receiveCycleAnalyticsDataSuccess),
      };
    }

    beforeEach(() => {
      state = { ...state, currentGroup, startDate, endDate };
    });

    it(`dispatches actions for required value stream analytics analytics data`, () => {
      return testAction(
        actions.fetchCycleAnalyticsData,
        state,
        null,
        [],
        [
          { type: 'requestCycleAnalyticsData' },
          { type: 'fetchValueStreams' },
          { type: 'receiveCycleAnalyticsDataSuccess' },
        ],
      );
    });

    it(`displays an error if fetchStageMedianValues fails`, () => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchStageMedianValues: stageActions.fetchStageMedianValues({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(stageActions.receiveStageMedianValuesError({ commit: () => {} })),
          commit: () => {},
          state: { ...state },
          getters: {
            ...getters,
            activeStages,
          },
        }),
      });

      return actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          shouldFlashAMessage('There was an error fetching median data for stages');
        });
    });

    it(`displays an error if fetchGroupStagesAndEvents fails`, () => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchGroupStagesAndEvents: actions.fetchGroupStagesAndEvents({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(actions.receiveGroupStagesError({ commit: () => {} })),
          commit: () => {},
          state: { ...state },
          getters,
        }),
      });

      return actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          shouldFlashAMessage('There was an error fetching value stream analytics stages.');
        });
    });
  });

  describe('receiveCycleAnalyticsDataError', () => {
    beforeEach(() => {});

    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} mutation on a 403 response`, () => {
      const response = { status: 403 };
      return testAction(
        actions.receiveCycleAnalyticsDataError,
        { response },
        state,
        [
          {
            type: types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR,
            payload: response.status,
          },
        ],
        [],
      );
    });

    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} mutation on a non 403 error response`, () => {
      const response = { status: 500 };
      return testAction(
        actions.receiveCycleAnalyticsDataError,
        { response },
        state,
        [
          {
            type: types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR,
            payload: response.status,
          },
        ],
        [],
      );
    });

    it('will flash an error when the response is not 403', () => {
      const response = { status: 500 };
      actions.receiveCycleAnalyticsDataError(
        {
          commit: () => {},
        },
        { response },
      );

      shouldFlashAMessage(flashErrorMessage);
    });
  });

  describe('receiveGroupStagesSuccess', () => {
    beforeEach(() => {});

    it(`commits the ${types.RECEIVE_GROUP_STAGES_SUCCESS} mutation and dispatches 'setDefaultSelectedStage'`, () => {
      return testAction(
        actions.receiveGroupStagesSuccess,
        { ...customizableStagesAndEvents.stages },
        state,
        [
          {
            type: types.RECEIVE_GROUP_STAGES_SUCCESS,
            payload: { ...customizableStagesAndEvents.stages },
          },
        ],
        [{ type: 'stages/setDefaultSelectedStage' }],
      );
    });
  });

  describe('initializeCycleAnalytics', () => {
    let mockDispatch;
    let mockCommit;
    let store;

    const selectedAuthor = 'Noam Chomsky';
    const selectedMilestone = '13.6';
    const selectedAssigneeList = ['nchom'];
    const selectedLabelList = ['label 1', 'label 2'];
    const initialData = {
      group: currentGroup,
      projectIds: [1, 2],
      milestonesPath,
      labelsPath,
      selectedAuthor,
      selectedMilestone,
      selectedAssigneeList,
      selectedLabelList,
    };

    beforeEach(() => {
      mockDispatch = jest.fn(() => Promise.resolve());
      mockCommit = jest.fn();
      store = {
        state,
        getters,
        commit: mockCommit,
        dispatch: mockDispatch,
      };
    });

    describe('with only group in initialData', () => {
      it('commits "INITIALIZE_CYCLE_ANALYTICS"', async () => {
        await actions.initializeCycleAnalytics(store, { group });
        expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_CYCLE_ANALYTICS', { group });
      });

      it('dispatches "fetchCycleAnalyticsData" and "initializeCycleAnalyticsSuccess"', async () => {
        await actions.initializeCycleAnalytics(store, { group });
        expect(mockDispatch).toHaveBeenCalledWith('fetchCycleAnalyticsData');
      });
    });

    describe('with initialData', () => {
      it.each`
        action                        | args
        ${'setPaths'}                 | ${{ milestonesPath, labelsPath, groupPath: currentGroup.fullPath }}
        ${'filters/initialize'}       | ${{ selectedAuthor, selectedMilestone, selectedAssigneeList, selectedLabelList }}
        ${'durationChart/setLoading'} | ${true}
        ${'typeOfWork/setLoading'}    | ${true}
      `('dispatches $action', async ({ action, args }) => {
        await actions.initializeCycleAnalytics(store, initialData);
        expect(mockDispatch).toHaveBeenCalledWith(action, args);
      });

      it('dispatches "fetchCycleAnalyticsData" and "initializeCycleAnalyticsSuccess"', async () => {
        await actions.initializeCycleAnalytics(store, initialData);
        expect(mockDispatch).toHaveBeenCalledWith('fetchCycleAnalyticsData');
        expect(mockDispatch).toHaveBeenCalledWith('initializeCycleAnalyticsSuccess');
      });

      it('commits "INITIALIZE_CYCLE_ANALYTICS"', async () => {
        await actions.initializeCycleAnalytics(store, initialData);
        expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_CYCLE_ANALYTICS', initialData);
      });
    });
  });

  describe('initializeCycleAnalyticsSuccess', () => {
    it(`commits the ${types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS} mutation`, () =>
      testAction(
        actions.initializeCycleAnalyticsSuccess,
        null,
        state,
        [{ type: types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS }],
        [],
      ));
  });

  describe('createValueStream', () => {
    const payload = { name: 'cool value stream' };
    const createResp = { id: 'new value stream', is_custom: true, ...payload };

    beforeEach(() => {
      state = { currentGroup };
    });

    describe('with no errors', () => {
      beforeEach(() => {
        mock.onPost(endpoints.valueStreamData).replyOnce(httpStatusCodes.OK, createResp);
      });

      it(`commits the ${types.REQUEST_CREATE_VALUE_STREAM} and ${types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS} actions`, () => {
        return testAction(
          actions.createValueStream,
          payload,
          state,
          [
            {
              type: types.REQUEST_CREATE_VALUE_STREAM,
            },
          ],
          [{ type: 'receiveCreateValueStreamSuccess', payload: createResp }],
        );
      });
    });

    describe('with errors', () => {
      const errors = { name: ['is taken'] };
      const message = { message: 'error' };
      const resp = { message, payload: { errors } };
      beforeEach(() => {
        mock.onPost(endpoints.valueStreamData).replyOnce(httpStatusCodes.NOT_FOUND, resp);
      });

      it(`commits the ${types.REQUEST_CREATE_VALUE_STREAM} and ${types.RECEIVE_CREATE_VALUE_STREAM_ERROR} actions `, () => {
        return testAction(
          actions.createValueStream,
          payload,
          state,
          [
            { type: types.REQUEST_CREATE_VALUE_STREAM },
            {
              type: types.RECEIVE_CREATE_VALUE_STREAM_ERROR,
              payload: { message, errors },
            },
          ],
          [],
        );
      });
    });
  });

  describe('deleteValueStream', () => {
    const payload = 'my-fake-value-stream';

    beforeEach(() => {
      state = { currentGroup };
    });

    describe('with no errors', () => {
      beforeEach(() => {
        mock.onDelete(endpoints.valueStreamData).replyOnce(httpStatusCodes.OK, {});
      });

      it(`commits the ${types.REQUEST_DELETE_VALUE_STREAM} and ${types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS} actions`, () => {
        return testAction(
          actions.deleteValueStream,
          payload,
          state,
          [
            {
              type: types.REQUEST_DELETE_VALUE_STREAM,
            },
            {
              type: types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS,
            },
          ],
          [{ type: 'fetchCycleAnalyticsData' }],
        );
      });
    });

    describe('with errors', () => {
      const message = { message: 'failed to delete the value stream' };
      const resp = { message };
      beforeEach(() => {
        mock.onDelete(endpoints.valueStreamData).replyOnce(httpStatusCodes.NOT_FOUND, resp);
      });

      it(`commits the ${types.REQUEST_DELETE_VALUE_STREAM} and ${types.RECEIVE_DELETE_VALUE_STREAM_ERROR} actions `, () => {
        return testAction(
          actions.deleteValueStream,
          payload,
          state,
          [
            { type: types.REQUEST_DELETE_VALUE_STREAM },
            {
              type: types.RECEIVE_DELETE_VALUE_STREAM_ERROR,
              payload: message,
            },
          ],
          [],
        );
      });
    });
  });

  describe('fetchValueStreams', () => {
    beforeEach(() => {
      state = {
        ...state,
        stages: [{ slug: selectedStageSlug }],
        currentGroup,
        featureFlags: {
          ...state.featureFlags,
          hasCreateMultipleValueStreams: true,
        },
      };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.valueStreamData).reply(httpStatusCodes.OK, { stages: [], events: [] });
    });

    it(`commits ${types.REQUEST_VALUE_STREAMS} and dispatches receiveValueStreamsSuccess with received data on success`, () => {
      return testAction(
        actions.fetchValueStreams,
        null,
        state,
        [{ type: types.REQUEST_VALUE_STREAMS }],
        [
          {
            payload: {
              events: [],
              stages: [],
            },
            type: 'receiveValueStreamsSuccess',
          },
        ],
      );
    });

    describe('with a failing request', () => {
      let mockCommit;
      beforeEach(() => {
        mockCommit = jest.fn();
        mock.onGet(endpoints.valueStreamData).reply(httpStatusCodes.NOT_FOUND);
      });

      it(`will commit ${types.RECEIVE_VALUE_STREAMS_ERROR}`, () => {
        return actions.fetchValueStreams({ state, getters, commit: mockCommit }).catch(() => {
          expect(mockCommit.mock.calls).toEqual([
            ['REQUEST_VALUE_STREAMS'],
            ['RECEIVE_VALUE_STREAMS_ERROR', httpStatusCodes.NOT_FOUND],
          ]);
        });
      });

      it(`throws an error`, () => {
        return expect(
          actions.fetchValueStreams({ state, getters, commit: mockCommit }),
        ).rejects.toThrow('Request failed with status code 404');
      });
    });

    describe('receiveValueStreamsSuccess', () => {
      it(`with a selectedValueStream in state commits the ${types.RECEIVE_VALUE_STREAMS_SUCCESS} mutation and dispatches 'fetchValueStreamData'`, () => {
        return testAction(
          actions.receiveValueStreamsSuccess,
          valueStreams,
          state,
          [
            {
              type: types.RECEIVE_VALUE_STREAMS_SUCCESS,
              payload: valueStreams,
            },
          ],
          [{ type: 'fetchValueStreamData' }],
        );
      });

      it(`commits the ${types.RECEIVE_VALUE_STREAMS_SUCCESS} mutation and dispatches 'setSelectedValueStream'`, () => {
        return testAction(
          actions.receiveValueStreamsSuccess,
          valueStreams,
          {
            ...state,
            selectedValueStream: null,
          },
          [
            {
              type: types.RECEIVE_VALUE_STREAMS_SUCCESS,
              payload: valueStreams,
            },
          ],
          [{ type: 'setSelectedValueStream', payload: selectedValueStream }],
        );
      });
    });

    describe('with hasCreateMultipleValueStreams disabled', () => {
      beforeEach(() => {
        state = {
          ...state,
          featureFlags: {
            ...state.featureFlags,
            hasCreateMultipleValueStreams: false,
          },
        };
      });

      it(`will dispatch the 'fetchGroupStagesAndEvents' request`, () =>
        testAction(actions.fetchValueStreams, null, state, [], [{ type: 'fetchValueStreamData' }]));
    });
  });

  describe('fetchValueStreamData', () => {
    beforeEach(() => {
      state = {
        ...state,
        stages: [{ slug: selectedStageSlug }],
        currentGroup,
        featureFlags: {
          ...state.featureFlags,
          hasCreateMultipleValueStreams: true,
        },
      };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.valueStreamData).reply(httpStatusCodes.OK, { stages: [], events: [] });
    });

    it('dispatches fetchGroupStagesAndEvents, fetchStageMedianValues and durationChart/fetchDurationData', () => {
      return testAction(
        actions.fetchValueStreamData,
        null,
        state,
        [],
        [
          { type: 'fetchGroupStagesAndEvents' },
          { type: 'stages/fetchStageMedianValues' },
          { type: 'durationChart/fetchDurationData' },
        ],
      );
    });
  });

  describe('setFilters', () => {
    it('dispatches the fetchCycleAnalyticsData action', () => {
      return testAction(actions.setFilters, null, state, [], [{ type: 'fetchCycleAnalyticsData' }]);
    });
  });
});

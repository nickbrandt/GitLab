import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as rootGetters from 'ee/analytics/cycle_analytics/store/getters';
import * as getters from 'ee/analytics/cycle_analytics/store/modules/type_of_work/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/type_of_work/actions';
import * as types from 'ee/analytics/cycle_analytics/store/modules/type_of_work/mutation_types';
import {
  TASKS_BY_TYPE_FILTERS,
  TASKS_BY_TYPE_SUBJECT_ISSUE,
} from 'ee/analytics/cycle_analytics/constants';

import httpStatusCodes from '~/lib/utils/http_status';
import { groupLabels, endpoints, startDate, endDate } from '../../../mock_data';
import { shouldFlashAMessage } from '../../../helpers';

const error = new Error(`Request failed with status code ${httpStatusCodes.NOT_FOUND}`);

describe('Type of work actions', () => {
  let mock;
  let state = {
    isLoadingTasksByTypeChart: false,
    isLoadingTasksByTypeChartTopLabels: false,

    subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
    topRankedLabels: [],
    selectedLabelIds: [],
    data: [],
  };

  const mockedState = {
    ...rootGetters,
    ...getters,
    ...state,
    rootState: { startDate, endDate },
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...mockedState, selectedGroup: null };
  });

  describe('fetchTopRankedGroupLabels', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
      state = { ...mockedState, subject: TASKS_BY_TYPE_SUBJECT_ISSUE };
    });

    describe('succeeds', () => {
      beforeEach(() => {
        mock.onGet(endpoints.tasksByTypeTopLabelsData).replyOnce(200, groupLabels);
      });

      it('dispatches receiveTopRankedGroupLabelsSuccess if the request succeeds', () => {
        return testAction(
          actions.fetchTopRankedGroupLabels,
          null,
          state,
          [{ type: 'REQUEST_TOP_RANKED_GROUP_LABELS' }],
          [{ type: 'receiveTopRankedGroupLabelsSuccess', payload: groupLabels }],
        );
      });

      describe('receiveTopRankedGroupLabelsSuccess', () => {
        beforeEach(() => {
          setFixtures('<div class="flash-container"></div>');
        });

        it(`commits the ${types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS} mutation and dispatches the 'fetchTasksByTypeData' action`, () => {
          return testAction(
            actions.receiveTopRankedGroupLabelsSuccess,
            null,
            state,
            [
              {
                type: types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS,
                payload: null,
              },
            ],
            [{ type: 'fetchTasksByTypeData' }],
          );
        });
      });
    });

    describe('with an error', () => {
      beforeEach(() => {
        mock.onGet(endpoints.fetchTopRankedGroupLabels).replyOnce(404);
      });

      it('dispatches receiveTopRankedGroupLabelsError if the request fails', () => {
        return testAction(
          actions.fetchTopRankedGroupLabels,
          null,
          state,
          [{ type: 'REQUEST_TOP_RANKED_GROUP_LABELS' }],
          [{ type: 'receiveTopRankedGroupLabelsError', payload: error }],
        );
      });
    });

    describe('receiveTopRankedGroupLabelsError', () => {
      beforeEach(() => {
        setFixtures('<div class="flash-container"></div>');
      });

      it('flashes an error message if the request fails', () => {
        actions.receiveTopRankedGroupLabelsError({
          commit: () => {},
        });

        shouldFlashAMessage('There was an error fetching the top labels for the selected group');
      });
    });
  });

  describe('setTasksByTypeFilters', () => {
    const filter = TASKS_BY_TYPE_FILTERS.SUBJECT;
    const value = 'issue';

    it(`commits the ${types.SET_TASKS_BY_TYPE_FILTERS} mutation and dispatches 'fetchTasksByTypeData'`, () => {
      return testAction(
        actions.setTasksByTypeFilters,
        { filter, value },
        {},
        [
          {
            type: types.SET_TASKS_BY_TYPE_FILTERS,
            payload: { filter, value },
          },
        ],
        [
          {
            type: 'fetchTasksByTypeData',
          },
        ],
      );
    });
  });
});

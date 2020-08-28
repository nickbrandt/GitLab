import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/shared/store/modules/filters/actions';
import * as types from 'ee/analytics/shared/store/modules/filters/mutation_types';
import initialState from 'ee/analytics/shared/store/modules/filters/state';
import httpStatusCodes from '~/lib/utils/http_status';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { filterMilestones, filterUsers, filterLabels } from './mock_data';

const milestonesEndpoint = 'fake_milestones_endpoint';
const labelsEndpoint = 'fake_labels_endpoint';
const groupEndpoint = 'fake_group_endpoint';

jest.mock('~/flash');

describe('Filters actions', () => {
  let state;
  let mock;
  let mockDispatch;
  let mockCommit;

  beforeEach(() => {
    state = initialState();
    mock = new MockAdapter(axios);

    mockDispatch = jest.fn().mockResolvedValue();
    mockCommit = jest.fn();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('initialize', () => {
    const initialData = {
      milestonesEndpoint,
      labelsEndpoint,
      groupEndpoint,
      selectedAuthor: 'Mr cool',
      selectedMilestone: 'NEXT',
    };

    it('does not dispatch', () => {
      const result = actions.initialize(
        {
          state,
          dispatch: mockDispatch,
          commit: mockCommit,
        },
        initialData,
      );
      expect(result).toBeUndefined();
      expect(mockDispatch).not.toHaveBeenCalled();
    });

    it(`commits the ${types.SET_SELECTED_FILTERS}`, () => {
      actions.initialize(
        {
          state,
          dispatch: mockDispatch,
          commit: mockCommit,
        },
        initialData,
      );
      expect(mockCommit).toHaveBeenCalledWith(types.SET_SELECTED_FILTERS, initialData);
    });
  });

  describe('setFilters', () => {
    const nextFilters = {
      selectedAuthor: 'Mr cool',
      selectedMilestone: 'NEXT',
    };

    it('dispatches the root/setFilters action', () => {
      return testAction(
        actions.setFilters,
        nextFilters,
        state,
        [
          {
            payload: nextFilters,
            type: types.SET_SELECTED_FILTERS,
          },
        ],
        [
          {
            type: 'setFilters',
            payload: nextFilters,
          },
        ],
      );
    });
  });

  describe('setEndpoints', () => {
    it('sets the api paths', () => {
      return testAction(
        actions.setEndpoints,
        { milestonesEndpoint, labelsEndpoint, groupEndpoint },
        state,
        [
          { payload: 'fake_milestones_endpoint', type: types.SET_MILESTONES_ENDPOINT },
          { payload: 'fake_labels_endpoint', type: types.SET_LABELS_ENDPOINT },
          { payload: 'fake_group_endpoint', type: types.SET_GROUP_ENDPOINT },
        ],
        [],
      );
    });
  });

  describe('fetchAuthors', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(httpStatusCodes.OK, filterUsers);
      });

      it('dispatches RECEIVE_AUTHORS_SUCCESS with received data', () => {
        return testAction(
          actions.fetchAuthors,
          null,
          state,
          [
            { type: types.REQUEST_AUTHORS },
            { type: types.RECEIVE_AUTHORS_SUCCESS, payload: filterUsers },
          ],
          [],
        ).then(({ data }) => {
          expect(data).toBe(filterUsers);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(httpStatusCodes.SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_AUTHORS_ERROR', () => {
        return testAction(
          actions.fetchAuthors,
          null,
          state,
          [
            { type: types.REQUEST_AUTHORS },
            {
              type: types.RECEIVE_AUTHORS_ERROR,
              payload: httpStatusCodes.SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => expect(createFlash).toHaveBeenCalled());
      });
    });
  });

  describe('fetchMilestones', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(milestonesEndpoint).replyOnce(httpStatusCodes.OK, filterMilestones);
      });

      it('dispatches RECEIVE_MILESTONES_SUCCESS with received data', () => {
        return testAction(
          actions.fetchMilestones,
          null,
          { ...state, milestonesEndpoint },
          [
            { type: types.REQUEST_MILESTONES },
            { type: types.RECEIVE_MILESTONES_SUCCESS, payload: filterMilestones },
          ],
          [],
        ).then(({ data }) => {
          expect(data).toBe(filterMilestones);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(httpStatusCodes.SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_MILESTONES_ERROR', () => {
        return testAction(
          actions.fetchMilestones,
          null,
          state,
          [
            { type: types.REQUEST_MILESTONES },
            {
              type: types.RECEIVE_MILESTONES_ERROR,
              payload: httpStatusCodes.SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => expect(createFlash).toHaveBeenCalled());
      });
    });
  });

  describe('fetchAssignees', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(httpStatusCodes.OK, filterUsers);
      });

      it('dispatches RECEIVE_ASSIGNEES_SUCCESS with received data', () => {
        return testAction(
          actions.fetchAssignees,
          null,
          { ...state, milestonesEndpoint },
          [
            { type: types.REQUEST_ASSIGNEES },
            { type: types.RECEIVE_ASSIGNEES_SUCCESS, payload: filterUsers },
          ],
          [],
        ).then(({ data }) => {
          expect(data).toBe(filterUsers);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(httpStatusCodes.SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_ASSIGNEES_ERROR', () => {
        return testAction(
          actions.fetchAssignees,
          null,
          state,
          [
            { type: types.REQUEST_ASSIGNEES },
            {
              type: types.RECEIVE_ASSIGNEES_ERROR,
              payload: httpStatusCodes.SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => expect(createFlash).toHaveBeenCalled());
      });
    });
  });

  describe('fetchLabels', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(labelsEndpoint).replyOnce(httpStatusCodes.OK, filterLabels);
      });

      it('dispatches RECEIVE_LABELS_SUCCESS with received data', () => {
        return testAction(
          actions.fetchLabels,
          null,
          { ...state, labelsEndpoint },
          [
            { type: types.REQUEST_LABELS },
            { type: types.RECEIVE_LABELS_SUCCESS, payload: filterLabels },
          ],
          [],
        ).then(({ data }) => {
          expect(data).toBe(filterLabels);
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onAny().replyOnce(httpStatusCodes.SERVICE_UNAVAILABLE);
      });

      it('dispatches RECEIVE_LABELS_ERROR', () => {
        return testAction(
          actions.fetchLabels,
          null,
          state,
          [
            { type: types.REQUEST_LABELS },
            {
              type: types.RECEIVE_LABELS_ERROR,
              payload: httpStatusCodes.SERVICE_UNAVAILABLE,
            },
          ],
          [],
        ).then(() => expect(createFlash).toHaveBeenCalled());
      });
    });
  });
});

import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/code_review_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/code_review_analytics/store/modules/filters/mutation_types';
import getInitialState from 'ee/analytics/code_review_analytics/store/modules/filters/state';
import createFlash from '~/flash';
import { mockMilestones, mockLabels } from '../../../mock_data';

jest.mock('~/flash', () => jest.fn());

describe('Code review analytics filters actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = getInitialState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setMilestonesEndpoint', () => {
    it('commits the SET_MILESTONES_ENDPOINT mutation', () =>
      testAction(
        actions.setMilestonesEndpoint,
        'milestone_path',
        state,
        [
          {
            type: types.SET_MILESTONES_ENDPOINT,
            payload: 'milestone_path',
          },
        ],
        [],
      ));
  });

  describe('setLabelsEndpoint', () => {
    it('commits the SET_LABELS_ENDPOINT mutation', () =>
      testAction(
        actions.setLabelsEndpoint,
        'labels_path',
        state,
        [
          {
            type: types.SET_LABELS_ENDPOINT,
            payload: 'labels_path',
          },
        ],
        [],
      ));
  });

  describe('fetchMilestones', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(state.milestonesEndpoint).replyOnce(200, mockMilestones);
      });

      it('dispatches success with received data', () => {
        testAction(
          actions.fetchMilestones,
          null,
          state,
          [
            { type: types.REQUEST_MILESTONES },
            { type: types.RECEIVE_MILESTONES_SUCCESS, payload: mockMilestones },
          ],
          [],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(state.milestonesEndpoint).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          actions.fetchMilestones,
          null,
          state,
          [
            { type: types.REQUEST_MILESTONES },
            {
              type: types.RECEIVE_MILESTONES_ERROR,
              payload: 500,
            },
          ],
          [],
          () => {
            expect(createFlash).toHaveBeenCalled();
            done();
          },
        );
      });
    });
  });

  describe('fetchLabels', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(state.labelsEndpoint).replyOnce(200, mockLabels);
      });

      it('dispatches success with received data', () => {
        testAction(
          actions.fetchLabels,
          null,
          state,
          [
            { type: types.REQUEST_LABELS },
            { type: types.RECEIVE_LABELS_SUCCESS, payload: mockLabels },
          ],
          [],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(state.labelsEndpoint).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          actions.fetchLabels,
          null,
          state,
          [
            { type: types.REQUEST_LABELS },
            {
              type: types.RECEIVE_LABELS_ERROR,
              payload: 500,
            },
          ],
          [],
          () => {
            expect(createFlash).toHaveBeenCalled();
            done();
          },
        );
      });
    });
  });

  describe('setFilters', () => {
    const selectedMilestone = 'my milestone';
    const selectedLabels = ['first label', 'second label'];

    it('commits the SET_FILTERS mutation', () => {
      testAction(
        actions.setFilters,
        { milestone_title: selectedMilestone, label_name: selectedLabels },
        state,
        [
          {
            type: types.SET_FILTERS,
            payload: { selectedMilestone, selectedLabels },
          },
        ],
        [
          { type: 'mergeRequests/setPage', payload: 1 },
          { type: 'mergeRequests/fetchMergeRequests', payload: null },
        ],
      );
    });
  });
});

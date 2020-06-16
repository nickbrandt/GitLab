import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/cycle_analytics/store/modules/filters/mutation_types';
import initialState from 'ee/analytics/cycle_analytics/store/modules/filters/state';
import createFlash from '~/flash';
import { filterMilestones, filterUsers, filterLabels } from '../../../mock_data';

const milestonesPath = 'fake_milestones_path';
const labelsPath = 'fake_labels_path';

jest.mock('~/flash', () => jest.fn());

describe('Filters actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = initialState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setFilters', () => {
    const nextFilters = {
      selectedAuthor: 'Mr cool',
      selectedMilestone: 'NEXT',
    };

    it('dispatches the root/setSelectedFilters action', () => {
      return testAction(
        actions.setFilters,
        nextFilters,
        state,
        [],
        [
          {
            type: 'setSelectedFilters',
            payload: {
              ...nextFilters,
              selectedLabels: [],
            },
          },
        ],
      );
    });

    it('sets the selectedLabels from the labels available', () => {
      return testAction(
        actions.setFilters,
        { ...nextFilters, selectedLabels: [filterLabels[1].title] },
        { ...state, labels: { data: filterLabels } },
        [],
        [
          {
            type: 'setSelectedFilters',
            payload: {
              ...nextFilters,
              selectedLabels: [filterLabels[1]],
            },
          },
        ],
      );
    });
  });

  describe('setPaths', () => {
    it('sets the api paths and dispatches requests for initial data', () => {
      return testAction(
        actions.setPaths,
        { milestonesPath, labelsPath },
        state,
        [
          { payload: 'fake_milestones_path.json', type: types.SET_MILESTONES_PATH },
          { payload: 'fake_labels_path.json', type: types.SET_LABELS_PATH },
        ],
        [],
      );
    });
  });
});

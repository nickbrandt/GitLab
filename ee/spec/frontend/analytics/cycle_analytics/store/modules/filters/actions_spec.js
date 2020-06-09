import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/filters/actions';
import * as types from 'ee/analytics/cycle_analytics/store/modules/filters/mutation_types';

describe('Filters actions', () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  describe('setPaths', () => {
    it('dispatches error', () => {
      return testAction(
        actions.setPaths,
        {
          milestonesPath: 'milestones_path',
          labelsPath: 'labels_path',
        },
        state,
        [
          { payload: 'milestones_path', type: types.SET_MILESTONES_PATH },
          { payload: 'labels_path', type: types.SET_LABELS_PATH },
        ],
        [],
      );
    });
  });
});

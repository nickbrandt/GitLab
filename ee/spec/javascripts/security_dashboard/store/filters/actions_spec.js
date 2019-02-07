import testAction from 'spec/helpers/vuex_action_helper';

import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as types from 'ee/security_dashboard/store/modules/filters/mutation_types';
import * as actions from 'ee/security_dashboard/store/modules/filters/actions';

describe('filters actions', () => {
  describe('setFilter', () => {
    it('should commit the SET_FILTER mutuation', done => {
      const state = createState();
      const payload = { filterId: 'type', optionId: 'sast' };

      testAction(
        actions.setFilter,
        payload,
        state,
        [
          {
            type: types.SET_FILTER,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setFilterOptions', () => {
    it('should commit the SET_FILTER_OPTIONS mutuation', done => {
      const state = createState();
      const payload = { filterId: 'project', options: [] };

      testAction(
        actions.setFilterOptions,
        payload,
        state,
        [
          {
            type: types.SET_FILTER_OPTIONS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setAllFilters', () => {
    it('should commit the SET_ALL_FILTERS mutuation', done => {
      const state = createState();
      const payload = { project_id: ['12', '15'] };

      testAction(
        actions.setAllFilters,
        payload,
        state,
        [
          {
            type: types.SET_ALL_FILTERS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });
});

import testAction from 'spec/helpers/vuex_action_helper';
import Tracking from '~/tracking';
import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as types from 'ee/security_dashboard/store/modules/filters/mutation_types';
import module, * as actions from 'ee/security_dashboard/store/modules/filters/actions';

describe('filters actions', () => {
  beforeEach(() => {
    spyOn(Tracking, 'event');
  });

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

  describe('setHideDismissedToggleInitialState', () => {
    it('should not do anything if hide_dismissed param is not present', done => {
      spyOnDependency(module, 'getParameterValues').and.returnValue([]);
      const state = createState();
      testAction(actions.setHideDismissedToggleInitialState, {}, state, [], [], done);
    });

    it('should commit the SET_TOGGLE_VALUE mutation if hide_dismissed param is present', done => {
      const state = createState();
      spyOnDependency(module, 'getParameterValues').and.returnValue([false]);

      testAction(
        actions.setHideDismissedToggleInitialState,
        {},
        state,
        [
          {
            type: types.SET_TOGGLE_VALUE,
            payload: {
              key: 'hide_dismissed',
              value: false,
            },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setToggleValue', () => {
    it('should commit the SET_TOGGLE_VALUE mutation', done => {
      const state = createState();
      const payload = { key: 'foo', value: 'bar' };

      testAction(
        actions.setToggleValue,
        payload,
        state,
        [
          {
            type: types.SET_TOGGLE_VALUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });
});

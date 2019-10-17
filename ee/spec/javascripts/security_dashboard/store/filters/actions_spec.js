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
    [
      {
        description: 'should set hideDismissed to true if scope param is not present',
        returnValue: [],
        hideDismissedValue: true,
      },
      {
        description: 'should set hideDismissed to false if scope param is "all"',
        returnValue: ['all'],
        hideDismissedValue: false,
      },
      {
        description: 'should set hideDismissed to true if scope param is "dismissed"',
        returnValue: ['dismissed'],
        hideDismissedValue: true,
      },
    ].forEach(testCase => {
      it(testCase.description, done => {
        spyOnDependency(module, 'getParameterValues').and.returnValue(testCase.returnValue);
        const state = createState();
        testAction(
          actions.setHideDismissedToggleInitialState,
          {},
          state,
          [
            {
              type: types.SET_TOGGLE_VALUE,
              payload: {
                key: 'hideDismissed',
                value: testCase.hideDismissedValue,
              },
            },
          ],
          [],
          done,
        );
      });
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

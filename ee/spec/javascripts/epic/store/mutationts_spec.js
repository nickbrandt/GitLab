import mutations from 'ee/epic/store/mutations';
import * as types from 'ee/epic/store/mutation_types';

import { dateTypes } from 'ee/epic/constants';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('Epic Store Mutations', () => {
  describe('SET_EPIC_META', () => {
    it('Should add Epic meta to state', () => {
      const state = {};
      mutations[types.SET_EPIC_META](state, mockEpicMeta);

      expect(state).toEqual(mockEpicMeta);
    });
  });

  describe('SET_EPIC_DATA', () => {
    it('Should add Epic data to state', () => {
      const state = {};
      mutations[types.SET_EPIC_DATA](state, mockEpicData);

      expect(state).toEqual(mockEpicData);
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `true`', () => {
      const state = {};
      mutations[types.REQUEST_EPIC_STATUS_CHANGE](state);

      expect(state.epicStatusChangeInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE_SUCCESS', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `false` and update Epic `state`', () => {
      const state = {
        state: 'opened',
      };
      mutations[types.REQUEST_EPIC_STATUS_CHANGE_SUCCESS](state, { state: 'closed' });

      expect(state.epicStatusChangeInProgress).toBe(false);
      expect(state.state).toBe('closed');
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE_FAILURE', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `false`', () => {
      const state = {};
      mutations[types.REQUEST_EPIC_STATUS_CHANGE_FAILURE](state);

      expect(state.epicStatusChangeInProgress).toBe(false);
    });
  });

  describe('TOGGLE_SIDEBAR', () => {
    it('Should set `sidebarCollapsed` flag on state with value of provided `sidebarCollapsed` param', () => {
      const state = {};
      const sidebarCollapsed = true;

      mutations[types.TOGGLE_SIDEBAR](state, sidebarCollapsed);

      expect(state.sidebarCollapsed).toBe(sidebarCollapsed);
    });
  });

  describe('REQUEST_EPIC_TODO_TOGGLE', () => {
    it('Should set `epicTodoToggleInProgress` flag on state as `true`', () => {
      const state = {
        epicTodoToggleInProgress: false,
      };

      mutations[types.REQUEST_EPIC_TODO_TOGGLE](state);

      expect(state.epicTodoToggleInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPIC_TODO_TOGGLE_SUCCESS', () => {
    it('Should set `todoDeletePath` value on state with provided value of `todoDeletePath` param', () => {
      const todoDeletePath = '/foo/bar';
      const state = {};

      mutations[types.REQUEST_EPIC_TODO_TOGGLE_SUCCESS](state, { todoDeletePath });

      expect(state.todoDeletePath).toBe(todoDeletePath);
    });

    it('Should toggle value of `todoExists` value on state', () => {
      const state = {
        todoExists: true,
      };

      mutations[types.REQUEST_EPIC_TODO_TOGGLE_SUCCESS](state, {});

      expect(state.todoExists).toBe(false);
    });

    it('Should set `epicTodoToggleInProgress` flag on state as `false`', () => {
      const state = {
        epicTodoToggleInProgress: true,
      };

      mutations[types.REQUEST_EPIC_TODO_TOGGLE_SUCCESS](state, {});

      expect(state.epicTodoToggleInProgress).toBe(false);
    });
  });

  describe('REQUEST_EPIC_TODO_TOGGLE_FAILURE', () => {
    it('Should set `epicTodoToggleInProgress` flag on state as `false`', () => {
      const state = {
        epicTodoToggleInProgress: true,
      };

      mutations[types.REQUEST_EPIC_TODO_TOGGLE_FAILURE](state);

      expect(state.epicTodoToggleInProgress).toBe(false);
    });
  });

  describe('TOGGLE_EPIC_START_DATE_TYPE', () => {
    it('Should set `startDateIsFixed` flag on state based on provided `dateTypeIsFixed` param', () => {
      const state = {
        startDateIsFixed: false,
      };

      mutations[types.TOGGLE_EPIC_START_DATE_TYPE](state, {
        dateTypeIsFixed: true,
      });

      expect(state.startDateIsFixed).toBe(true);
    });
  });

  describe('TOGGLE_EPIC_DUE_DATE_TYPE', () => {
    it('Should set `dueDateIsFixed` flag on state based on provided `dateTypeIsFixed` param', () => {
      const state = {
        dueDateIsFixed: false,
      };

      mutations[types.TOGGLE_EPIC_DUE_DATE_TYPE](state, {
        dateTypeIsFixed: true,
      });

      expect(state.dueDateIsFixed).toBe(true);
    });
  });

  describe('REQUEST_EPIC_DATE_SAVE', () => {
    it('Should set `epicStartDateSaveInProgress` flag on state as `true` when provided `dateType` param is `start`', () => {
      const state = {
        epicStartDateSaveInProgress: false,
      };

      mutations[types.REQUEST_EPIC_DATE_SAVE](state, {
        dateType: dateTypes.start,
      });

      expect(state.epicStartDateSaveInProgress).toBe(true);
    });

    it('Should set `epicDueDateSaveInProgress` flag on state as `true` when provided `dateType` param is `due`', () => {
      const state = {
        epicDueDateSaveInProgress: false,
      };

      mutations[types.REQUEST_EPIC_DATE_SAVE](state, {
        dateType: dateTypes.due,
      });

      expect(state.epicDueDateSaveInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPIC_DATE_SAVE_SUCCESS', () => {
    it('Should set `epicStartDateSaveInProgress` flag on state to `false` and set `startDateIsFixed` & `startDate` values based on provided `dateTypeIsFixed` & `newDate` params when `dateType` param is `start`', () => {
      const startDateIsFixed = true;
      const startDate = '2018-1-1';
      const state = {};

      mutations[types.REQUEST_EPIC_DATE_SAVE_SUCCESS](state, {
        dateType: dateTypes.start,
        dateTypeIsFixed: startDateIsFixed,
        newDate: startDate,
      });

      expect(state.epicStartDateSaveInProgress).toBe(false);
      expect(state.startDateIsFixed).toBe(startDateIsFixed);
      expect(state.startDate).toBe(startDate);
    });

    it('Should set `epicDueDateSaveInProgress` flag on state to `false` and set `dueDateIsFixed` & `dueDate` values based on provided `dateTypeIsFixed` & `newDate` params when `dateType` param is `due`', () => {
      const dueDateIsFixed = true;
      const dueDate = '2018-1-1';
      const state = {};

      mutations[types.REQUEST_EPIC_DATE_SAVE_SUCCESS](state, {
        dateType: dateTypes.due,
        dateTypeIsFixed: dueDateIsFixed,
        newDate: dueDate,
      });

      expect(state.epicDueDateSaveInProgress).toBe(false);
      expect(state.dueDateIsFixed).toBe(dueDateIsFixed);
      expect(state.dueDate).toBe(dueDate);
    });
  });

  describe('REQUEST_EPIC_DATE_SAVE_FAILURE', () => {
    it('Should set `epicStartDateSaveInProgress` flag on state to `false` and set `startDateIsFixed` value with provided `dateTypeIsFixed` param when `dateType` param is `start`', () => {
      const startDateIsFixed = true;
      const state = {};

      mutations[types.REQUEST_EPIC_DATE_SAVE_FAILURE](state, {
        dateType: dateTypes.start,
        dateTypeIsFixed: startDateIsFixed,
      });

      expect(state.epicStartDateSaveInProgress).toBe(false);
      expect(state.startDateIsFixed).toBe(startDateIsFixed);
    });

    it('Should set `epicDueDateSaveInProgress` flag on state to `false` and set `dueDateIsFixed` value with provided `dateTypeIsFixed` param when `dateType` param is `due`', () => {
      const dueDateIsFixed = true;
      const state = {};

      mutations[types.REQUEST_EPIC_DATE_SAVE_FAILURE](state, {
        dateType: dateTypes.due,
        dateTypeIsFixed: dueDateIsFixed,
      });

      expect(state.epicDueDateSaveInProgress).toBe(false);
      expect(state.dueDateIsFixed).toBe(dueDateIsFixed);
    });
  });
});

import * as types from './mutation_types';

export default {
  [types.SET_EPIC_META](state, meta) {
    Object.assign(state, { ...meta });
  },

  [types.SET_EPIC_DATA](state, data) {
    Object.assign(state, { ...data });
  },

  [types.REQUEST_EPIC_STATUS_CHANGE](state) {
    state.epicStatusChangeInProgress = true;
  },
  [types.REQUEST_EPIC_STATUS_CHANGE_SUCCESS](state, data) {
    state.state = data.state;
    state.epicStatusChangeInProgress = false;
  },
  [types.REQUEST_EPIC_STATUS_CHANGE_FAILURE](state) {
    state.epicStatusChangeInProgress = false;
  },

  [types.TOGGLE_SIDEBAR](state, isSidebarCollapsed) {
    state.sidebarCollapsed = isSidebarCollapsed;
  },

  [types.REQUEST_EPIC_TODO_TOGGLE](state) {
    state.epicTodoToggleInProgress = true;
  },
  [types.REQUEST_EPIC_TODO_TOGGLE_SUCCESS](state, { todoDeletePath }) {
    state.todoDeletePath = todoDeletePath;
    state.todoExists = !state.todoExists;
    state.epicTodoToggleInProgress = false;
  },
  [types.REQUEST_EPIC_TODO_TOGGLE_FAILURE](state) {
    state.epicTodoToggleInProgress = false;
  },
};

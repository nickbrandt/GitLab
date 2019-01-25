import flash from '~/flash';
import { __ } from '~/locale';

import axios from '~/lib/utils/axios_utils';

import epicUtils from '../utils/epic_utils';
import { statusType, statusEvent } from '../constants';

import * as types from './mutation_types';

export const setEpicMeta = ({ commit }, meta) => commit(types.SET_EPIC_META, meta);

export const setEpicData = ({ commit }, data) => commit(types.SET_EPIC_DATA, data);

export const requestEpicStatusChange = ({ commit }) => commit(types.REQUEST_EPIC_STATUS_CHANGE);

export const requestEpicStatusChangeSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_STATUS_CHANGE_SUCCESS, data);

export const requestEpicStatusChangeFailure = ({ commit }) => {
  commit(types.REQUEST_EPIC_STATUS_CHANGE_FAILURE);
  flash(__('Unable to update this epic at this time.'));
};

export const triggerIssuableEvent = (_, { isEpicOpen }) => {
  // Ensure that status change is reflected across the page.
  // As `Close`/`Reopen` button is also present under
  // comment form (part of Notes app) We've wrapped
  // call to `$(document).trigger` within `triggerDocumentEvent`
  // for ease of testing
  epicUtils.triggerDocumentEvent('issuable_vue_app:change', isEpicOpen);
  epicUtils.triggerDocumentEvent('issuable:change', isEpicOpen);
};

export const toggleEpicStatus = ({ state, dispatch }, isEpicOpen) => {
  dispatch('requestEpicStatusChange');

  const statusEventType = isEpicOpen ? statusEvent.close : statusEvent.reopen;
  const queryParam = `epic[state_event]=${statusEventType}`;

  axios
    .put(`${state.endpoint}.json?${encodeURI(queryParam)}`)
    .then(({ data }) => {
      dispatch('requestEpicStatusChangeSuccess', data);
      dispatch('triggerIssuableEvent', { isEpicOpen: data.state === statusType.close });
    })
    .catch(() => {
      dispatch('requestEpicStatusChangeFailure');
      dispatch('triggerIssuableEvent', { isEpicOpen: !isEpicOpen });
    });
};

export const toggleSidebarFlag = ({ commit }, sidebarCollapsed) =>
  commit(types.TOGGLE_SIDEBAR, sidebarCollapsed);
export const toggleContainerClassAndCookie = (_, sidebarCollapsed) => {
  epicUtils.toggleContainerClass('right-sidebar-expanded');
  epicUtils.toggleContainerClass('right-sidebar-collapsed');

  epicUtils.setCollapsedGutter(sidebarCollapsed);
};
export const toggleSidebar = ({ dispatch }, { sidebarCollapsed }) => {
  dispatch('toggleContainerClassAndCookie', !sidebarCollapsed);
  dispatch('toggleSidebarFlag', !sidebarCollapsed);
};

/**
 * Methods to handle toggling Todo from sidebar
 */
export const requestEpicTodoToggle = ({ commit }) => commit(types.REQUEST_EPIC_TODO_TOGGLE);
export const requestEpicTodoToggleSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_TODO_TOGGLE_SUCCESS, data);
export const requestEpicTodoToggleFailure = ({ commit, state }, data) => {
  commit(types.REQUEST_EPIC_TODO_TOGGLE_FAILURE, data);

  if (state.todoExists) {
    flash(__('There was an error deleting the todo.'));
  } else {
    flash(__('There was an error adding a todo.'));
  }
};
export const triggerTodoToggleEvent = (_, { count }) => {
  epicUtils.triggerDocumentEvent('todo:toggle', count);
};
export const toggleTodo = ({ state, dispatch }) => {
  let reqPromise;

  dispatch('requestEpicTodoToggle');

  if (!state.todoExists) {
    reqPromise = axios.post(state.todoPath, {
      issuable_id: state.epicId,
      issuable_type: 'epic',
    });
  } else {
    reqPromise = axios.delete(state.todoDeletePath);
  }

  reqPromise
    .then(({ data }) => {
      dispatch('triggerTodoToggleEvent', { count: data.count });
      dispatch('requestEpicTodoToggleSuccess', { todoDeletePath: data.delete_path });
    })
    .catch(() => {
      dispatch('requestEpicTodoToggleFailure');
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};

import { pull, union } from 'lodash';
import Vue from 'vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { formatIssue, moveIssueListHelper } from '../boards_util';
import * as mutationTypes from './mutation_types';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

export const removeIssueFromList = ({ state, listId, issueId }) => {
  Vue.set(state.boardItemsByListId, listId, pull(state.boardItemsByListId[listId], issueId));
  const list = state.boardLists[listId];
  Vue.set(state.boardLists, listId, { ...list, issuesCount: list.issuesCount - 1 });
};

export const addIssueToList = ({ state, listId, issueId, moveBeforeId, moveAfterId, atIndex }) => {
  const listIssues = state.boardItemsByListId[listId];
  let newIndex = atIndex || 0;
  if (moveBeforeId) {
    newIndex = listIssues.indexOf(moveBeforeId) + 1;
  } else if (moveAfterId) {
    newIndex = listIssues.indexOf(moveAfterId);
  }
  listIssues.splice(newIndex, 0, issueId);
  Vue.set(state.boardItemsByListId, listId, listIssues);
  const list = state.boardLists[listId];
  Vue.set(state.boardLists, listId, { ...list, issuesCount: list.issuesCount + 1 });
};

export default {
  [mutationTypes.SET_INITIAL_BOARD_DATA](state, data) {
    const { boardType, disabled, boardId, fullPath, boardConfig, isEpicBoard } = data;
    state.boardId = boardId;
    state.fullPath = fullPath;
    state.boardType = boardType;
    state.disabled = disabled;
    state.boardConfig = boardConfig;
    state.isEpicBoard = isEpicBoard;
  },

  [mutationTypes.RECEIVE_BOARD_LISTS_SUCCESS]: (state, lists) => {
    state.boardLists = lists;
  },

  [mutationTypes.RECEIVE_BOARD_LISTS_FAILURE]: (state) => {
    state.error = s__(
      'Boards|An error occurred while fetching the board lists. Please reload the page.',
    );
  },

  [mutationTypes.SET_ACTIVE_ID](state, { id, sidebarType }) {
    state.activeId = id;
    state.sidebarType = sidebarType;
  },

  [mutationTypes.SET_FILTERS](state, filterParams) {
    state.filterParams = filterParams;
  },

  [mutationTypes.CREATE_LIST_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while creating the list. Please try again.');
  },

  [mutationTypes.RECEIVE_LABELS_REQUEST]: (state) => {
    state.labelsLoading = true;
  },

  [mutationTypes.RECEIVE_LABELS_SUCCESS]: (state, labels) => {
    state.labels = labels;
    state.labelsLoading = false;
  },

  [mutationTypes.RECEIVE_LABELS_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while fetching labels. Please reload the page.');
    state.labelsLoading = false;
  },

  [mutationTypes.GENERATE_DEFAULT_LISTS_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while generating lists. Please reload the page.');
  },

  [mutationTypes.REQUEST_ADD_LIST]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_LIST_SUCCESS]: (state, list) => {
    Vue.set(state.boardLists, list.id, list);
  },

  [mutationTypes.RECEIVE_ADD_LIST_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.MOVE_LIST]: (state, { movedList, listAtNewIndex }) => {
    const { boardLists } = state;
    Vue.set(boardLists, movedList.id, movedList);
    Vue.set(boardLists, listAtNewIndex.id, listAtNewIndex);
  },

  [mutationTypes.UPDATE_LIST_FAILURE]: (state, backupList) => {
    state.error = s__('Boards|An error occurred while updating the list. Please try again.');
    Vue.set(state, 'boardLists', backupList);
  },

  [mutationTypes.TOGGLE_LIST_COLLAPSED]: (state, { listId, collapsed }) => {
    Vue.set(state.boardLists[listId], 'collapsed', collapsed);
  },

  [mutationTypes.REMOVE_LIST]: (state, listId) => {
    Vue.delete(state.boardLists, listId);
  },

  [mutationTypes.REMOVE_LIST_FAILURE](state, listsBackup) {
    state.error = s__('Boards|An error occurred while removing the list. Please try again.');
    state.boardLists = listsBackup;
  },

  [mutationTypes.REQUEST_ITEMS_FOR_LIST]: (state, { listId, fetchNext }) => {
    Vue.set(state.listsFlags, listId, { [fetchNext ? 'isLoadingMore' : 'isLoading']: true });
  },

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_SUCCESS]: (state, { listItems, listPageInfo, listId }) => {
    const { listData, boardItems } = listItems;
    Vue.set(state, 'boardItems', { ...state.boardItems, ...boardItems });
    Vue.set(
      state.boardItemsByListId,
      listId,
      union(state.boardItemsByListId[listId] || [], listData[listId]),
    );
    Vue.set(state.pageInfoByListId, listId, listPageInfo[listId]);
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_FAILURE]: (state, listId) => {
    state.error = s__(
      'Boards|An error occurred while fetching the board issues. Please reload the page.',
    );
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.RESET_ISSUES]: (state) => {
    Object.keys(state.boardItemsByListId).forEach((listId) => {
      Vue.set(state.boardItemsByListId, listId, []);
    });
  },

  [mutationTypes.UPDATE_ISSUE_BY_ID]: (state, { issueId, prop, value }) => {
    if (!state.boardItems[issueId]) {
      /* eslint-disable-next-line @gitlab/require-i18n-strings */
      throw new Error('No issue found.');
    }

    Vue.set(state.boardItems[issueId], prop, value);
  },

  [mutationTypes.SET_ASSIGNEE_LOADING](state, isLoading) {
    state.isSettingAssignees = isLoading;
  },

  [mutationTypes.REQUEST_ADD_ISSUE]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_ISSUE_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_ISSUE_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.MOVE_ISSUE]: (
    state,
    { originalIssue, fromListId, toListId, moveBeforeId, moveAfterId },
  ) => {
    const fromList = state.boardLists[fromListId];
    const toList = state.boardLists[toListId];

    const issue = moveIssueListHelper(originalIssue, fromList, toList);
    Vue.set(state.boardItems, issue.id, issue);

    removeIssueFromList({ state, listId: fromListId, issueId: issue.id });
    addIssueToList({ state, listId: toListId, issueId: issue.id, moveBeforeId, moveAfterId });
  },

  [mutationTypes.MOVE_ISSUE_SUCCESS]: (state, { issue }) => {
    const issueId = getIdFromGraphQLId(issue.id);
    Vue.set(state.boardItems, issueId, formatIssue({ ...issue, id: issueId }));
  },

  [mutationTypes.MOVE_ISSUE_FAILURE]: (
    state,
    { originalIssue, fromListId, toListId, originalIndex },
  ) => {
    state.error = s__('Boards|An error occurred while moving the issue. Please try again.');
    Vue.set(state.boardItems, originalIssue.id, originalIssue);
    removeIssueFromList({ state, listId: toListId, issueId: originalIssue.id });
    addIssueToList({
      state,
      listId: fromListId,
      issueId: originalIssue.id,
      atIndex: originalIndex,
    });
  },

  [mutationTypes.REQUEST_UPDATE_ISSUE]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_UPDATE_ISSUE_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_UPDATE_ISSUE_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.CREATE_ISSUE_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while creating the issue. Please try again.');
  },

  [mutationTypes.ADD_ISSUE_TO_LIST]: (state, { list, issue, position }) => {
    addIssueToList({
      state,
      listId: list.id,
      issueId: issue.id,
      atIndex: position,
    });
    Vue.set(state.boardItems, issue.id, issue);
  },

  [mutationTypes.ADD_ISSUE_TO_LIST_FAILURE]: (state, { list, issueId }) => {
    state.error = s__('Boards|An error occurred while creating the issue. Please try again.');
    removeIssueFromList({ state, listId: list.id, issueId });
  },

  [mutationTypes.REMOVE_ISSUE_FROM_LIST]: (state, { list, issue }) => {
    removeIssueFromList({ state, listId: list.id, issueId: issue.id });
    Vue.delete(state.boardItems, issue.id);
  },

  [mutationTypes.SET_CURRENT_PAGE]: () => {
    notImplemented();
  },

  [mutationTypes.TOGGLE_EMPTY_STATE]: () => {
    notImplemented();
  },

  [mutationTypes.REQUEST_GROUP_PROJECTS]: (state, fetchNext) => {
    Vue.set(state, 'groupProjectsFlags', {
      [fetchNext ? 'isLoadingMore' : 'isLoading']: true,
      pageInfo: state.groupProjectsFlags.pageInfo,
    });
  },

  [mutationTypes.RECEIVE_GROUP_PROJECTS_SUCCESS]: (state, { projects, pageInfo, fetchNext }) => {
    Vue.set(state, 'groupProjects', fetchNext ? [...state.groupProjects, ...projects] : projects);
    Vue.set(state, 'groupProjectsFlags', { isLoading: false, isLoadingMore: false, pageInfo });
  },

  [mutationTypes.RECEIVE_GROUP_PROJECTS_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while fetching group projects. Please try again.');
    Vue.set(state, 'groupProjectsFlags', { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.SET_SELECTED_PROJECT]: (state, project) => {
    state.selectedProject = project;
  },

  [mutationTypes.ADD_BOARD_ITEM_TO_SELECTION]: (state, boardItem) => {
    state.selectedBoardItems = [...state.selectedBoardItems, boardItem];
  },

  [mutationTypes.REMOVE_BOARD_ITEM_FROM_SELECTION]: (state, boardItem) => {
    Vue.set(
      state,
      'selectedBoardItems',
      state.selectedBoardItems.filter((obj) => obj !== boardItem),
    );
  },

  [mutationTypes.SET_ADD_COLUMN_FORM_VISIBLE]: (state, visible) => {
    Vue.set(state.addColumnForm, 'visible', visible);
  },

  [mutationTypes.ADD_LIST_TO_HIGHLIGHTED_LISTS]: (state, listId) => {
    state.highlightedLists.push(listId);
  },

  [mutationTypes.REMOVE_LIST_FROM_HIGHLIGHTED_LISTS]: (state, listId) => {
    state.highlightedLists = state.highlightedLists.filter((id) => id !== listId);
  },

  [mutationTypes.RESET_BOARD_ITEM_SELECTION]: (state) => {
    state.selectedBoardItems = [];
  },
};

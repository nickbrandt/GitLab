import testAction from 'helpers/vuex_action_helper';
import {
  fullBoardId,
  formatListIssues,
  formatBoardLists,
  formatIssueInput,
} from '~/boards/boards_util';
import { inactiveId, ISSUABLE } from '~/boards/constants';
import destroyBoardListMutation from '~/boards/graphql/board_list_destroy.mutation.graphql';
import issueCreateMutation from '~/boards/graphql/issue_create.mutation.graphql';
import issueMoveListMutation from '~/boards/graphql/issue_move_list.mutation.graphql';
import actions, { gqlClient } from '~/boards/stores/actions';
import * as types from '~/boards/stores/mutation_types';
import {
  mockLists,
  mockListsById,
  mockIssue,
  mockIssue2,
  rawIssue,
  mockIssues,
  mockMilestone,
  labels,
  mockActiveIssue,
  mockGroupProjects,
} from '../mock_data';

jest.mock('~/flash');

const expectNotImplemented = (action) => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

// We need this helper to make sure projectPath is including
// subgroups when the movIssue action is called.
const getProjectPath = (path) => path.split('#')[0];

beforeEach(() => {
  window.gon = { features: {} };
});

describe('setInitialBoardData', () => {
  it('sets data object', () => {
    const mockData = {
      foo: 'bar',
      bar: 'baz',
    };

    return testAction(
      actions.setInitialBoardData,
      mockData,
      {},
      [{ type: types.SET_INITIAL_BOARD_DATA, payload: mockData }],
      [],
    );
  });
});

describe('setFilters', () => {
  it('should commit mutation SET_FILTERS', (done) => {
    const state = {
      filters: {},
    };

    const filters = { labelName: 'label' };

    testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: { ...filters, not: {} } }],
      [],
      done,
    );
  });
});

describe('performSearch', () => {
  it('should dispatch setFilters action', (done) => {
    testAction(actions.performSearch, {}, {}, [], [{ type: 'setFilters', payload: {} }], done);
  });

  it('should dispatch setFilters, fetchLists and resetIssues action when graphqlBoardLists FF is on', (done) => {
    window.gon = { features: { graphqlBoardLists: true } };
    testAction(
      actions.performSearch,
      {},
      {},
      [],
      [{ type: 'setFilters', payload: {} }, { type: 'fetchLists' }, { type: 'resetIssues' }],
      done,
    );
  });
});

describe('setActiveId', () => {
  it('should commit mutation SET_ACTIVE_ID', (done) => {
    const state = {
      activeId: inactiveId,
    };

    testAction(
      actions.setActiveId,
      { id: 1, sidebarType: 'something' },
      state,
      [{ type: types.SET_ACTIVE_ID, payload: { id: 1, sidebarType: 'something' } }],
      [],
      done,
    );
  });
});

describe('fetchLists', () => {
  it('should dispatch fetchIssueLists action', () => {
    testAction({
      action: actions.fetchLists,
      expectedActions: [{ type: 'fetchIssueLists' }],
    });
  });
});

describe('fetchIssueLists', () => {
  const state = {
    fullPath: 'gitlab-org',
    boardId: '1',
    filterParams: {},
    boardType: 'group',
  };

  let queryResponse = {
    data: {
      group: {
        board: {
          hideBacklogList: true,
          lists: {
            nodes: [mockLists[1]],
          },
        },
      },
    },
  };

  const formattedLists = formatBoardLists(queryResponse.data.group.board.lists);

  it('should commit mutations RECEIVE_BOARD_LISTS_SUCCESS on success', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchIssueLists,
      {},
      state,
      [
        {
          type: types.RECEIVE_BOARD_LISTS_SUCCESS,
          payload: formattedLists,
        },
      ],
      [],
      done,
    );
  });

  it('should commit mutations RECEIVE_BOARD_LISTS_FAILURE on failure', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    testAction(
      actions.fetchIssueLists,
      {},
      state,
      [
        {
          type: types.RECEIVE_BOARD_LISTS_FAILURE,
        },
      ],
      [],
      done,
    );
  });

  it('dispatch createList action when backlog list does not exist and is not hidden', (done) => {
    queryResponse = {
      data: {
        group: {
          board: {
            hideBacklogList: false,
            lists: {
              nodes: [mockLists[1]],
            },
          },
        },
      },
    };
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchIssueLists,
      {},
      state,
      [
        {
          type: types.RECEIVE_BOARD_LISTS_SUCCESS,
          payload: formattedLists,
        },
      ],
      [{ type: 'createList', payload: { backlog: true } }],
      done,
    );
  });
});

describe('createList', () => {
  it('should dispatch createIssueList action', () => {
    testAction({
      action: actions.createList,
      payload: { backlog: true },
      expectedActions: [{ type: 'createIssueList', payload: { backlog: true } }],
    });
  });
});

describe('createIssueList', () => {
  let commit;
  let dispatch;
  let getters;
  let state;

  beforeEach(() => {
    state = {
      fullPath: 'gitlab-org',
      boardId: '1',
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'closed' }],
    };
    commit = jest.fn();
    dispatch = jest.fn();
    getters = {
      getListByLabelId: jest.fn(),
    };
  });

  it('should dispatch addList action when creating backlog list', async () => {
    const backlogList = {
      id: 'gid://gitlab/List/1',
      listType: 'backlog',
      title: 'Open',
      position: 0,
    };

    jest.spyOn(gqlClient, 'mutate').mockReturnValue(
      Promise.resolve({
        data: {
          boardListCreate: {
            list: backlogList,
            errors: [],
          },
        },
      }),
    );

    await actions.createIssueList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('addList', backlogList);
  });

  it('dispatches highlightList after addList has succeeded', async () => {
    const list = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Open',
      labelId: '4',
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        boardListCreate: {
          list,
          errors: [],
        },
      },
    });

    await actions.createIssueList({ getters, state, commit, dispatch }, { labelId: '4' });

    expect(dispatch).toHaveBeenCalledWith('addList', list);
    expect(dispatch).toHaveBeenCalledWith('highlightList', list.id);
  });

  it('should commit CREATE_LIST_FAILURE mutation when API returns an error', async () => {
    jest.spyOn(gqlClient, 'mutate').mockReturnValue(
      Promise.resolve({
        data: {
          boardListCreate: {
            list: {},
            errors: [{ foo: 'bar' }],
          },
        },
      }),
    );

    await actions.createIssueList({ getters, state, commit, dispatch }, { backlog: true });

    expect(commit).toHaveBeenCalledWith(types.CREATE_LIST_FAILURE);
  });

  it('highlights list and does not re-query if it already exists', async () => {
    const existingList = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Some label',
      position: 1,
    };

    getters = {
      getListByLabelId: jest.fn().mockReturnValue(existingList),
    };

    await actions.createIssueList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('highlightList', existingList.id);
    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(commit).not.toHaveBeenCalled();
  });
});

describe('fetchLabels', () => {
  it('should commit mutation RECEIVE_LABELS_SUCCESS on success', async () => {
    const queryResponse = {
      data: {
        group: {
          labels: {
            nodes: labels,
          },
        },
      },
    };
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const commit = jest.fn();
    const getters = {
      shouldUseGraphQL: () => true,
    };
    const state = { boardType: 'group' };

    await actions.fetchLabels({ getters, state, commit });

    expect(commit).toHaveBeenCalledWith(types.RECEIVE_LABELS_SUCCESS, labels);
  });
});

describe('moveList', () => {
  it('should commit MOVE_LIST mutation and dispatch updateList action', (done) => {
    const initialBoardListsState = {
      'gid://gitlab/List/1': mockLists[0],
      'gid://gitlab/List/2': mockLists[1],
    };

    const state = {
      fullPath: 'gitlab-org',
      boardId: '1',
      boardType: 'group',
      disabled: false,
      boardLists: initialBoardListsState,
    };

    testAction(
      actions.moveList,
      {
        listId: 'gid://gitlab/List/1',
        replacedListId: 'gid://gitlab/List/2',
        newIndex: 1,
        adjustmentValue: 1,
      },
      state,
      [
        {
          type: types.MOVE_LIST,
          payload: { movedList: mockLists[0], listAtNewIndex: mockLists[1] },
        },
      ],
      [
        {
          type: 'updateList',
          payload: {
            listId: 'gid://gitlab/List/1',
            position: 0,
            backupList: initialBoardListsState,
          },
        },
      ],
      done,
    );
  });

  it('should not commit MOVE_LIST or dispatch updateList if listId and replacedListId are the same', () => {
    const initialBoardListsState = {
      'gid://gitlab/List/1': mockLists[0],
      'gid://gitlab/List/2': mockLists[1],
    };

    const state = {
      fullPath: 'gitlab-org',
      boardId: '1',
      boardType: 'group',
      disabled: false,
      boardLists: initialBoardListsState,
    };

    testAction(
      actions.moveList,
      {
        listId: 'gid://gitlab/List/1',
        replacedListId: 'gid://gitlab/List/1',
        newIndex: 1,
        adjustmentValue: 1,
      },
      state,
      [],
      [],
    );
  });
});

describe('updateList', () => {
  it('should commit UPDATE_LIST_FAILURE mutation when API returns an error', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateBoardList: {
          list: {},
          errors: [{ foo: 'bar' }],
        },
      },
    });

    const state = {
      fullPath: 'gitlab-org',
      boardId: '1',
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'closed' }],
    };

    testAction(
      actions.updateList,
      { listId: 'gid://gitlab/List/1', position: 1 },
      state,
      [{ type: types.UPDATE_LIST_FAILURE }],
      [],
      done,
    );
  });
});

describe('toggleListCollapsed', () => {
  it('should commit TOGGLE_LIST_COLLAPSED mutation', async () => {
    const payload = { listId: 'gid://gitlab/List/1', collapsed: true };
    await testAction({
      action: actions.toggleListCollapsed,
      payload,
      expectedMutations: [
        {
          type: types.TOGGLE_LIST_COLLAPSED,
          payload,
        },
      ],
    });
  });
});

describe('removeList', () => {
  let state;
  const list = mockLists[0];
  const listId = list.id;
  const mutationVariables = {
    mutation: destroyBoardListMutation,
    variables: {
      listId,
    },
  };

  beforeEach(() => {
    state = {
      boardLists: mockListsById,
    };
  });

  afterEach(() => {
    state = null;
  });

  it('optimistically deletes the list', () => {
    const commit = jest.fn();

    actions.removeList({ commit, state }, listId);

    expect(commit.mock.calls).toEqual([[types.REMOVE_LIST, listId]]);
  });

  it('keeps the updated list if remove succeeds', async () => {
    const commit = jest.fn();
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        destroyBoardList: {
          errors: [],
        },
      },
    });

    await actions.removeList({ commit, state }, listId);

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
    expect(commit.mock.calls).toEqual([[types.REMOVE_LIST, listId]]);
  });

  it('restores the list if update fails', async () => {
    const commit = jest.fn();
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue(Promise.reject());

    await actions.removeList({ commit, state }, listId);

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
    expect(commit.mock.calls).toEqual([
      [types.REMOVE_LIST, listId],
      [types.REMOVE_LIST_FAILURE, mockListsById],
    ]);
  });

  it('restores the list if update response has errors', async () => {
    const commit = jest.fn();
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        destroyBoardList: {
          errors: ['update failed, ID invalid'],
        },
      },
    });

    await actions.removeList({ commit, state }, listId);

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
    expect(commit.mock.calls).toEqual([
      [types.REMOVE_LIST, listId],
      [types.REMOVE_LIST_FAILURE, mockListsById],
    ]);
  });
});

describe('fetchItemsForList', () => {
  const listId = mockLists[0].id;

  const state = {
    fullPath: 'gitlab-org',
    boardId: '1',
    filterParams: {},
    boardType: 'group',
  };

  const mockIssuesNodes = mockIssues.map((issue) => ({ node: issue }));

  const pageInfo = {
    endCursor: '',
    hasNextPage: false,
  };

  const queryResponse = {
    data: {
      group: {
        board: {
          lists: {
            nodes: [
              {
                id: listId,
                issues: {
                  edges: mockIssuesNodes,
                  pageInfo,
                },
              },
            ],
          },
        },
      },
    },
  };

  const formattedIssues = formatListIssues(queryResponse.data.group.board.lists);

  const listPageInfo = {
    [listId]: pageInfo,
  };

  it('should commit mutations REQUEST_ITEMS_FOR_LIST and RECEIVE_ITEMS_FOR_LIST_SUCCESS on success', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchItemsForList,
      { listId },
      state,
      [
        {
          type: types.REQUEST_ITEMS_FOR_LIST,
          payload: { listId, fetchNext: false },
        },
        {
          type: types.RECEIVE_ITEMS_FOR_LIST_SUCCESS,
          payload: { listItems: formattedIssues, listPageInfo, listId },
        },
      ],
      [],
      done,
    );
  });

  it('should commit mutations REQUEST_ITEMS_FOR_LIST and RECEIVE_ITEMS_FOR_LIST_FAILURE on failure', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    testAction(
      actions.fetchItemsForList,
      { listId },
      state,
      [
        {
          type: types.REQUEST_ITEMS_FOR_LIST,
          payload: { listId, fetchNext: false },
        },
        { type: types.RECEIVE_ITEMS_FOR_LIST_FAILURE, payload: listId },
      ],
      [],
      done,
    );
  });
});

describe('resetIssues', () => {
  it('commits RESET_ISSUES mutation', () => {
    return testAction(actions.resetIssues, {}, {}, [{ type: types.RESET_ISSUES }], []);
  });
});

describe('moveIssue', () => {
  const listIssues = {
    'gid://gitlab/List/1': [436, 437],
    'gid://gitlab/List/2': [],
  };

  const issues = {
    436: mockIssue,
    437: mockIssue2,
  };

  const state = {
    fullPath: 'gitlab-org',
    boardId: '1',
    boardType: 'group',
    disabled: false,
    boardLists: mockLists,
    boardItemsByListId: listIssues,
    boardItems: issues,
  };

  it('should commit MOVE_ISSUE mutation and MOVE_ISSUE_SUCCESS mutation when successful', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: rawIssue,
          errors: [],
        },
      },
    });

    testAction(
      actions.moveIssue,
      {
        issueId: '436',
        issueIid: mockIssue.iid,
        issuePath: mockIssue.referencePath,
        fromListId: 'gid://gitlab/List/1',
        toListId: 'gid://gitlab/List/2',
      },
      state,
      [
        {
          type: types.MOVE_ISSUE,
          payload: {
            originalIssue: mockIssue,
            fromListId: 'gid://gitlab/List/1',
            toListId: 'gid://gitlab/List/2',
          },
        },
        {
          type: types.MOVE_ISSUE_SUCCESS,
          payload: { issue: rawIssue },
        },
      ],
      [],
      done,
    );
  });

  it('calls mutate with the correct variables', () => {
    const mutationVariables = {
      mutation: issueMoveListMutation,
      variables: {
        projectPath: getProjectPath(mockIssue.referencePath),
        boardId: fullBoardId(state.boardId),
        iid: mockIssue.iid,
        fromListId: 1,
        toListId: 2,
        moveBeforeId: undefined,
        moveAfterId: undefined,
      },
    };
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: rawIssue,
          errors: [],
        },
      },
    });

    actions.moveIssue(
      { state, commit: () => {} },
      {
        issueId: mockIssue.id,
        issueIid: mockIssue.iid,
        issuePath: mockIssue.referencePath,
        fromListId: 'gid://gitlab/List/1',
        toListId: 'gid://gitlab/List/2',
      },
    );

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
  });

  it('should commit MOVE_ISSUE mutation and MOVE_ISSUE_FAILURE mutation when unsuccessful', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: {},
          errors: [{ foo: 'bar' }],
        },
      },
    });

    testAction(
      actions.moveIssue,
      {
        issueId: '436',
        issueIid: mockIssue.iid,
        issuePath: mockIssue.referencePath,
        fromListId: 'gid://gitlab/List/1',
        toListId: 'gid://gitlab/List/2',
      },
      state,
      [
        {
          type: types.MOVE_ISSUE,
          payload: {
            originalIssue: mockIssue,
            fromListId: 'gid://gitlab/List/1',
            toListId: 'gid://gitlab/List/2',
          },
        },
        {
          type: types.MOVE_ISSUE_FAILURE,
          payload: {
            originalIssue: mockIssue,
            fromListId: 'gid://gitlab/List/1',
            toListId: 'gid://gitlab/List/2',
            originalIndex: 0,
          },
        },
      ],
      [],
      done,
    );
  });
});

describe('setAssignees', () => {
  const node = { username: 'name' };
  const projectPath = 'h/h';
  const refPath = `${projectPath}#3`;
  const iid = '1';

  describe('when succeeds', () => {
    it('calls the correct mutation with the correct values', (done) => {
      testAction(
        actions.setAssignees,
        [node],
        { activeIssue: { iid, referencePath: refPath }, commit: () => {} },
        [
          {
            type: 'UPDATE_ISSUE_BY_ID',
            payload: { prop: 'assignees', issueId: undefined, value: [node] },
          },
        ],
        [],
        done,
      );
    });
  });
});

describe('createNewIssue', () => {
  const state = {
    boardType: 'group',
    fullPath: 'gitlab-org/gitlab',
    boardConfig: {
      labelIds: [],
      assigneeId: null,
      milestoneId: -1,
    },
  };

  const stateWithBoardConfig = {
    boardConfig: {
      labels: [
        {
          id: 5,
          title: 'Test',
          color: '#ff0000',
          description: 'testing;',
          textColor: 'white',
        },
      ],
      assigneeId: 2,
      milestoneId: 3,
    },
  };

  it('should return issue from API on success', async () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createIssue: {
          issue: mockIssue,
          errors: [],
        },
      },
    });

    const result = await actions.createNewIssue({ state }, mockIssue);
    expect(result).toEqual(mockIssue);
  });

  it('should add board scope to the issue being created', async () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createIssue: {
          issue: mockIssue,
          errors: [],
        },
      },
    });

    await actions.createNewIssue({ state: stateWithBoardConfig }, mockIssue);
    expect(gqlClient.mutate).toHaveBeenCalledWith({
      mutation: issueCreateMutation,
      variables: {
        input: formatIssueInput(mockIssue, stateWithBoardConfig.boardConfig),
      },
    });
  });

  it('should add board scope by merging attributes to the issue being created', async () => {
    const issue = {
      ...mockIssue,
      assigneeIds: ['gid://gitlab/User/1'],
      labelIds: ['gid://gitlab/GroupLabel/4'],
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createIssue: {
          issue,
          errors: [],
        },
      },
    });

    const payload = formatIssueInput(issue, stateWithBoardConfig.boardConfig);

    await actions.createNewIssue({ state: stateWithBoardConfig }, issue);
    expect(gqlClient.mutate).toHaveBeenCalledWith({
      mutation: issueCreateMutation,
      variables: {
        input: formatIssueInput(issue, stateWithBoardConfig.boardConfig),
      },
    });
    expect(payload.labelIds).toEqual(['gid://gitlab/GroupLabel/4', 'gid://gitlab/GroupLabel/5']);
    expect(payload.assigneeIds).toEqual(['gid://gitlab/User/1', 'gid://gitlab/User/2']);
  });

  it('should commit CREATE_ISSUE_FAILURE mutation when API returns an error', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createIssue: {
          issue: mockIssue,
          errors: [{ foo: 'bar' }],
        },
      },
    });

    const payload = mockIssue;

    testAction(
      actions.createNewIssue,
      payload,
      state,
      [{ type: types.CREATE_ISSUE_FAILURE }],
      [],
      done,
    );
  });
});

describe('addListIssue', () => {
  it('should commit ADD_ISSUE_TO_LIST mutation', (done) => {
    const payload = {
      list: mockLists[0],
      issue: mockIssue,
      position: 0,
    };

    testAction(
      actions.addListIssue,
      payload,
      {},
      [{ type: types.ADD_ISSUE_TO_LIST, payload }],
      [],
      done,
    );
  });
});

describe('setActiveIssueLabels', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeIssue: mockIssue };
  const testLabelIds = labels.map((label) => label.id);
  const input = {
    addLabelIds: testLabelIds,
    removeLabelIds: [],
    projectPath: 'h/b',
  };

  it('should assign labels on success', (done) => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { issue: { labels: { nodes: labels } } } } });

    const payload = {
      issueId: getters.activeIssue.id,
      prop: 'labels',
      value: labels,
    };

    testAction(
      actions.setActiveIssueLabels,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_ISSUE_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueLabels({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveIssueDueDate', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeIssue: mockIssue };
  const testDueDate = '2020-02-20';
  const input = {
    dueDate: testDueDate,
    projectPath: 'h/b',
  };

  it('should commit due date after setting the issue', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateIssue: {
          issue: {
            dueDate: testDueDate,
          },
          errors: [],
        },
      },
    });

    const payload = {
      issueId: getters.activeIssue.id,
      prop: 'dueDate',
      value: testDueDate,
    };

    testAction(
      actions.setActiveIssueDueDate,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_ISSUE_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueDueDate({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveIssueSubscribed', () => {
  const state = { boardItems: { [mockActiveIssue.id]: mockActiveIssue } };
  const getters = { activeIssue: mockActiveIssue };
  const subscribedState = true;
  const input = {
    subscribedState,
    projectPath: 'gitlab-org/gitlab-test',
  };

  it('should commit subscribed status', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueSetSubscription: {
          issue: {
            subscribed: subscribedState,
          },
          errors: [],
        },
      },
    });

    const payload = {
      issueId: getters.activeIssue.id,
      prop: 'subscribed',
      value: subscribedState,
    };

    testAction(
      actions.setActiveIssueSubscribed,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_ISSUE_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { issueSetSubscription: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueSubscribed({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveIssueMilestone', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeIssue: mockIssue };
  const testMilestone = {
    ...mockMilestone,
    id: 'gid://gitlab/Milestone/1',
  };
  const input = {
    milestoneId: testMilestone.id,
    projectPath: 'h/b',
  };

  it('should commit milestone after setting the issue', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateIssue: {
          issue: {
            milestone: testMilestone,
          },
          errors: [],
        },
      },
    });

    const payload = {
      issueId: getters.activeIssue.id,
      prop: 'milestone',
      value: testMilestone,
    };

    testAction(
      actions.setActiveIssueMilestone,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_ISSUE_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueMilestone({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveIssueTitle', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeIssue: mockIssue };
  const testTitle = 'Test Title';
  const input = {
    title: testTitle,
    projectPath: 'h/b',
  };

  it('should commit title after setting the issue', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateIssue: {
          issue: {
            title: testTitle,
          },
          errors: [],
        },
      },
    });

    const payload = {
      issueId: getters.activeIssue.id,
      prop: 'title',
      value: testTitle,
    };

    testAction(
      actions.setActiveIssueTitle,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_ISSUE_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueTitle({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('fetchGroupProjects', () => {
  const state = {
    fullPath: 'gitlab-org',
  };

  const pageInfo = {
    endCursor: '',
    hasNextPage: false,
  };

  const queryResponse = {
    data: {
      group: {
        projects: {
          nodes: mockGroupProjects,
          pageInfo: {
            endCursor: '',
            hasNextPage: false,
          },
        },
      },
    },
  };

  it('should commit mutations REQUEST_GROUP_PROJECTS and RECEIVE_GROUP_PROJECTS_SUCCESS on success', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchGroupProjects,
      {},
      state,
      [
        {
          type: types.REQUEST_GROUP_PROJECTS,
          payload: false,
        },
        {
          type: types.RECEIVE_GROUP_PROJECTS_SUCCESS,
          payload: { projects: mockGroupProjects, pageInfo, fetchNext: false },
        },
      ],
      [],
      done,
    );
  });

  it('should commit mutations REQUEST_GROUP_PROJECTS and RECEIVE_GROUP_PROJECTS_FAILURE on failure', (done) => {
    jest.spyOn(gqlClient, 'query').mockRejectedValue();

    testAction(
      actions.fetchGroupProjects,
      {},
      state,
      [
        {
          type: types.REQUEST_GROUP_PROJECTS,
          payload: false,
        },
        {
          type: types.RECEIVE_GROUP_PROJECTS_FAILURE,
        },
      ],
      [],
      done,
    );
  });
});

describe('setSelectedProject', () => {
  it('should commit mutation SET_SELECTED_PROJECT', (done) => {
    const project = mockGroupProjects[0];

    testAction(
      actions.setSelectedProject,
      project,
      {},
      [
        {
          type: types.SET_SELECTED_PROJECT,
          payload: project,
        },
      ],
      [],
      done,
    );
  });
});

describe('toggleBoardItemMultiSelection', () => {
  const boardItem = mockIssue;
  const boardItem2 = mockIssue2;

  it('should commit mutation ADD_BOARD_ITEM_TO_SELECTION if item is not on selection state', () => {
    testAction(
      actions.toggleBoardItemMultiSelection,
      boardItem,
      { selectedBoardItems: [] },
      [
        {
          type: types.ADD_BOARD_ITEM_TO_SELECTION,
          payload: boardItem,
        },
      ],
      [],
    );
  });

  it('should commit mutation REMOVE_BOARD_ITEM_FROM_SELECTION if item is on selection state', () => {
    testAction(
      actions.toggleBoardItemMultiSelection,
      boardItem,
      { selectedBoardItems: [mockIssue] },
      [
        {
          type: types.REMOVE_BOARD_ITEM_FROM_SELECTION,
          payload: boardItem,
        },
      ],
      [],
    );
  });

  it('should additionally commit mutation ADD_BOARD_ITEM_TO_SELECTION for active issue and dispatch unsetActiveId', () => {
    testAction(
      actions.toggleBoardItemMultiSelection,
      boardItem2,
      { activeId: mockActiveIssue.id, activeIssue: mockActiveIssue, selectedBoardItems: [] },
      [
        {
          type: types.ADD_BOARD_ITEM_TO_SELECTION,
          payload: mockActiveIssue,
        },
        {
          type: types.ADD_BOARD_ITEM_TO_SELECTION,
          payload: boardItem2,
        },
      ],
      [{ type: 'unsetActiveId' }],
    );
  });
});

describe('resetBoardItemMultiSelection', () => {
  it('should commit mutation RESET_BOARD_ITEM_SELECTION', () => {
    testAction({
      action: actions.resetBoardItemMultiSelection,
      state: { selectedBoardItems: [mockIssue] },
      expectedMutations: [
        {
          type: types.RESET_BOARD_ITEM_SELECTION,
        },
      ],
    });
  });
});

describe('toggleBoardItem', () => {
  it('should dispatch resetBoardItemMultiSelection and unsetActiveId when boardItem is the active item', () => {
    testAction({
      action: actions.toggleBoardItem,
      payload: { boardItem: mockIssue },
      state: {
        activeId: mockIssue.id,
      },
      expectedActions: [{ type: 'resetBoardItemMultiSelection' }, { type: 'unsetActiveId' }],
    });
  });

  it('should dispatch resetBoardItemMultiSelection and setActiveId when boardItem is not the active item', () => {
    testAction({
      action: actions.toggleBoardItem,
      payload: { boardItem: mockIssue },
      state: {
        activeId: inactiveId,
      },
      expectedActions: [
        { type: 'resetBoardItemMultiSelection' },
        { type: 'setActiveId', payload: { id: mockIssue.id, sidebarType: ISSUABLE } },
      ],
    });
  });
});

describe('fetchBacklog', () => {
  expectNotImplemented(actions.fetchBacklog);
});

describe('bulkUpdateIssues', () => {
  expectNotImplemented(actions.bulkUpdateIssues);
});

describe('fetchIssue', () => {
  expectNotImplemented(actions.fetchIssue);
});

describe('toggleIssueSubscription', () => {
  expectNotImplemented(actions.toggleIssueSubscription);
});

describe('showPage', () => {
  expectNotImplemented(actions.showPage);
});

describe('toggleEmptyState', () => {
  expectNotImplemented(actions.toggleEmptyState);
});

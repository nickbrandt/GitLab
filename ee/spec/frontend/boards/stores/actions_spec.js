import axios from 'axios';
import boardsStoreEE from 'ee/boards/stores/boards_store_ee';
import actions from 'ee/boards/stores/actions';
import * as types from 'ee/boards/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';

jest.mock('axios');

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

describe('toggleShowLabels', () => {
  it('should commit mutation TOGGLE_LABELS', done => {
    const state = {
      isShowingLabels: true,
    };

    testAction(actions.toggleShowLabels, null, state, [{ type: types.TOGGLE_LABELS }], [], done);
  });
});

describe('setActiveListId', () => {
  it('should commit mutation SET_ACTIVE_LIST_ID', done => {
    const state = {
      activeListId: 0,
    };

    testAction(
      actions.setActiveListId,
      1,
      state,
      [{ type: types.SET_ACTIVE_LIST_ID, payload: 1 }],
      [],
      done,
    );
  });
});

describe('updateListWipLimit', () => {
  let storeMock;

  beforeEach(() => {
    storeMock = {
      state: { endpoints: { listsEndpoint: '/test' } },
      create: () => {},
      setCurrentBoard: () => {},
    };

    boardsStoreEE.initEESpecific(storeMock);
  });

  it('should call the correct url', () => {
    axios.put.mockResolvedValue({ data: {} });
    const maxIssueCount = 0;
    const activeListId = 1;

    return actions.updateListWipLimit({ state: { activeListId } }, { maxIssueCount }).then(() => {
      expect(axios.put).toHaveBeenCalledWith(
        `${boardsStoreEE.store.state.endpoints.listsEndpoint}/${activeListId}`,
        { list: { max_issue_count: maxIssueCount } },
      );
    });
  });
});

describe('fetchAllBoards', () => {
  expectNotImplemented(actions.fetchAllBoards);
});

describe('fetchRecentBoards', () => {
  expectNotImplemented(actions.fetchRecentBoards);
});

describe('createBoard', () => {
  expectNotImplemented(actions.createBoard);
});

describe('deleteBoard', () => {
  expectNotImplemented(actions.deleteBoard);
});

describe('updateIssueWeight', () => {
  expectNotImplemented(actions.updateIssueWeight);
});

describe('togglePromotionState', () => {
  expectNotImplemented(actions.updateIssueWeight);
});

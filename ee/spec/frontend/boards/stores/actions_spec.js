import axios from 'axios';
import boardsStoreEE from 'ee/boards/stores/boards_store_ee';
import actions from 'ee/boards/stores/actions';
import * as types from 'ee/boards/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { ListType } from '~/boards/constants';

jest.mock('axios');

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

describe('setShowLabels', () => {
  it('should commit mutation SET_SHOW_LABELS', done => {
    const state = {
      isShowingLabels: true,
    };

    testAction(
      actions.setShowLabels,
      false,
      state,
      [{ type: types.SET_SHOW_LABELS, payload: false }],
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
    const activeId = 1;

    return actions.updateListWipLimit({ state: { activeId } }, { maxIssueCount }).then(() => {
      expect(axios.put).toHaveBeenCalledWith(
        `${boardsStoreEE.store.state.endpoints.listsEndpoint}/${activeId}`,
        { list: { max_issue_count: maxIssueCount } },
      );
    });
  });
});

describe('showPromotionList', () => {
  it('should dispatch addList action when conditions showPromotion is true', done => {
    const state = {
      endpoints: { fullPath: 'gitlab-org', boardId: '1' },
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'backlog' }, { type: 'closed' }],
      showPromotion: true,
    };

    const promotionList = {
      id: 'promotion',
      listType: ListType.promotion,
      title: 'Improve Issue Boards',
      position: 0,
    };

    testAction(
      actions.showPromotionList,
      {},
      state,
      [],
      [{ type: 'addList', payload: promotionList }],
      done,
    );
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

describe('toggleEpicSwimlanes', () => {
  it('should commit mutation TOGGLE_EPICS_SWIMLANES', () => {
    const state = {
      isShowingEpicsSwimlanes: false,
      endpoints: {
        fullPath: 'gitlab-org',
        boardId: 1,
      },
    };

    return testAction(
      actions.toggleEpicSwimlanes,
      null,
      state,
      [{ type: types.TOGGLE_EPICS_SWIMLANES }],
      [],
    );
  });
});

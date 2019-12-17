import actions from 'ee/boards/stores/actions';
import * as types from 'ee/boards/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';

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

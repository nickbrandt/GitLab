import mutations from 'ee/boards/stores/mutations';
import { inactiveListId } from '~/boards/constants';
import { mockLists, mockEpics } from '../mock_data';

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

describe('TOGGLE_LABELS', () => {
  it('toggles isShowingLabels from true to false', () => {
    const state = {
      isShowingLabels: true,
    };

    mutations.TOGGLE_LABELS(state);

    expect(state.isShowingLabels).toBe(false);
  });

  it('toggles isShowingLabels from false to true', () => {
    const state = {
      isShowingLabels: false,
    };

    mutations.TOGGLE_LABELS(state);

    expect(state.isShowingLabels).toBe(true);
  });
});

describe('SET_ACTIVE_LIST_ID', () => {
  it('updates aciveListId to be the value that is passed', () => {
    const expectedId = 1;
    const state = {
      activeListId: inactiveListId,
    };

    mutations.SET_ACTIVE_LIST_ID(state, expectedId);

    expect(state.activeListId).toBe(expectedId);
  });
});

describe('REQUEST_AVAILABLE_BOARDS', () => {
  expectNotImplemented(mutations.REQUEST_AVAILABLE_BOARDS);
});

describe('RECEIVE_AVAILABLE_BOARDS_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_AVAILABLE_BOARDS_SUCCESS);
});

describe('RECEIVE_AVAILABLE_BOARDS_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_AVAILABLE_BOARDS_ERROR);
});

describe('REQUEST_RECENT_BOARDS', () => {
  expectNotImplemented(mutations.REQUEST_RECENT_BOARDS);
});

describe('RECEIVE_RECENT_BOARDS_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_RECENT_BOARDS_SUCCESS);
});

describe('RECEIVE_RECENT_BOARDS_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_RECENT_BOARDS_ERROR);
});

describe('REQUEST_ADD_BOARD', () => {
  expectNotImplemented(mutations.REQUEST_ADD_BOARD);
});

describe('RECEIVE_ADD_BOARD_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_BOARD_SUCCESS);
});

describe('RECEIVE_ADD_BOARD_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_BOARD_ERROR);
});

describe('REQUEST_REMOVE_BOARD', () => {
  expectNotImplemented(mutations.REQUEST_REMOVE_BOARD);
});

describe('RECEIVE_REMOVE_BOARD_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_REMOVE_BOARD_SUCCESS);
});

describe('RECEIVE_REMOVE_BOARD_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_REMOVE_BOARD_ERROR);
});

describe('TOGGLE_PROMOTION_STATE', () => {
  expectNotImplemented(mutations.TOGGLE_PROMOTION_STATE);
});

describe('TOGGLE_EPICS_SWIMLANES', () => {
  it('toggles isShowingEpicsSwimlanes from true to false', () => {
    const state = {
      isShowingEpicsSwimlanes: true,
    };

    mutations.TOGGLE_EPICS_SWIMLANES(state);

    expect(state.isShowingEpicsSwimlanes).toBe(false);
  });

  it('toggles isShowingEpicsSwimlanes from false to true', () => {
    const state = {
      isShowingEpicsSwimlanes: false,
    };

    mutations.TOGGLE_EPICS_SWIMLANES(state);

    expect(state.isShowingEpicsSwimlanes).toBe(true);
  });

  it('sets epicsSwimlanesFetchInProgress to true', () => {
    const state = {
      epicsSwimlanesFetchInProgress: false,
    };

    mutations.TOGGLE_EPICS_SWIMLANES(state);

    expect(state.epicsSwimlanesFetchInProgress).toBe(true);
  });
});

describe('RECEIVE_SWIMLANES_SUCCESS', () => {
  it('sets epicsSwimlanesFetchInProgress to false and populates epicsSwimlanes with payload', () => {
    const state = {
      epicsSwimlanesFetchInProgress: true,
      epicsSwimlanes: {},
    };

    mutations.RECEIVE_SWIMLANES_SUCCESS(state, mockLists);

    expect(state.epicsSwimlanesFetchInProgress).toBe(false);
    expect(state.epicsSwimlanes).toEqual(mockLists);
  });
});

describe('RECEIVE_SWIMLANES_FAILURE', () => {
  it('sets epicsSwimlanesFetchInProgress to false and epicsSwimlanesFetchFailure to true', () => {
    const state = {
      epicsSwimlanesFetchInProgress: true,
      epicsSwimlanesFetchFailure: false,
    };

    mutations.RECEIVE_SWIMLANES_FAILURE(state);

    expect(state.epicsSwimlanesFetchInProgress).toBe(false);
    expect(state.epicsSwimlanesFetchFailure).toBe(true);
  });
});

describe('RECEIVE_EPICS_SUCCESS', () => {
  it('populates epics with payload', () => {
    const state = {
      epics: {},
    };

    mutations.RECEIVE_EPICS_SUCCESS(state, mockEpics);

    expect(state.epics).toEqual(mockEpics);
  });
});

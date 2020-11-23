import * as types from 'ee/analytics/cycle_analytics/store/modules/stages/mutation_types';
import mutations from 'ee/analytics/cycle_analytics/store/modules/stages/mutations';

let state = null;

describe('Value Stream Analytics mutations', () => {
  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                               | stateKey                   | value
    ${types.REQUEST_REORDER_STAGE}         | ${'isSavingStageOrder'}    | ${true}
    ${types.RECEIVE_REORDER_STAGE_SUCCESS} | ${'isSavingStageOrder'}    | ${false}
    ${types.RECEIVE_REORDER_STAGE_ERROR}   | ${'isSavingStageOrder'}    | ${false}
    ${types.REQUEST_REORDER_STAGE}         | ${'errorSavingStageOrder'} | ${false}
    ${types.RECEIVE_REORDER_STAGE_SUCCESS} | ${'errorSavingStageOrder'} | ${false}
    ${types.RECEIVE_REORDER_STAGE_ERROR}   | ${'errorSavingStageOrder'} | ${true}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });
});

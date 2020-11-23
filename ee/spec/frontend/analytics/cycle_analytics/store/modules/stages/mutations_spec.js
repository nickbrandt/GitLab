import * as types from 'ee/analytics/cycle_analytics/store/modules/stages/mutation_types';
import mutations from 'ee/analytics/cycle_analytics/store/modules/stages/mutations';
import { issueEvents } from '../../../mock_data';

let state = null;

describe('Value Stream Analytics mutations', () => {
  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  // ${types.RECEIVE_STAGE_DATA_SUCCESS}    | ${'isEmptyStage'}          | ${true}
  // ${types.RECEIVE_STAGE_DATA_ERROR}      | ${'selectedStageError'}    | ${}
  it.each`
    mutation                               | stateKey                   | value
    ${types.REQUEST_STAGE_DATA}            | ${'isLoadingStage'}        | ${true}
    ${types.REQUEST_STAGE_DATA}            | ${'isEmptyStage'}          | ${false}
    ${types.REQUEST_STAGE_DATA}            | ${'selectedStageError'}    | ${''}
    ${types.RECEIVE_STAGE_DATA_ERROR}      | ${'isLoadingStage'}        | ${false}
    ${types.RECEIVE_STAGE_DATA_ERROR}      | ${'isEmptyStage'}          | ${true}
    ${types.RECEIVE_STAGE_DATA_SUCCESS}    | ${'isLoadingStage'}        | ${false}
    ${types.RECEIVE_STAGE_DATA_SUCCESS}    | ${'selectedStageError'}    | ${''}
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

  it.each`
    mutation                            | payload                  | expectedState
    ${types.SET_SELECTED_STAGE}         | ${{ id: 'first-stage' }} | ${{ selectedStage: { id: 'first-stage' } }}
    ${types.RECEIVE_STAGE_DATA_SUCCESS} | ${issueEvents}           | ${{ isEmptyStage: false }}
    ${types.RECEIVE_STAGE_DATA_ERROR}   | ${'Some error message'}  | ${{ selectedStageError: 'Some error message' }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = { selectedGroup: { fullPath: 'rad-stage' } };
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );
});

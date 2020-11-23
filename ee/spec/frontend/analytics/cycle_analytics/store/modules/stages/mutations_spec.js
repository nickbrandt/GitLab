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

  it.each`
    mutation                               | stateKey                   | value
    ${types.REQUEST_STAGE_MEDIANS}         | ${'medians'}               | ${{}}
    ${types.RECEIVE_STAGE_MEDIANS_ERROR}   | ${'medians'}               | ${{}}
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
    ${types.REQUEST_UPDATE_STAGE}          | ${'isLoading'}             | ${true}
    ${types.RECEIVE_UPDATE_STAGE_SUCCESS}  | ${'isLoading'}             | ${false}
    ${types.RECEIVE_UPDATE_STAGE_ERROR}    | ${'isLoading'}             | ${false}
    ${types.REQUEST_REMOVE_STAGE}          | ${'isLoading'}             | ${true}
    ${types.RECEIVE_REMOVE_STAGE_RESPONSE} | ${'isLoading'}             | ${false}
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

  describe(`${types.RECEIVE_STAGE_MEDIANS_SUCCESS}`, () => {
    it('sets each id as a key in the median object with the corresponding value and error', () => {
      const stateWithData = {
        medians: {},
      };

      mutations[types.RECEIVE_STAGE_MEDIANS_SUCCESS](stateWithData, [
        { id: 1, value: 20 },
        { id: 2, value: 10 },
      ]);

      expect(stateWithData.medians).toEqual({
        '1': { value: 20, error: null },
        '2': { value: 10, error: null },
      });
    });
  });
});

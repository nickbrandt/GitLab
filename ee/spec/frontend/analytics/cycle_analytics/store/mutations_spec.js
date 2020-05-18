import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';

import {
  issueStage,
  planStage,
  codeStage,
  stagingStage,
  reviewStage,
  totalStage,
  startDate,
  endDate,
  selectedProjects,
  customizableStagesAndEvents,
} from '../mock_data';

let state = null;

describe('Cycle analytics mutations', () => {
  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                                    | stateKey            | value
    ${types.REQUEST_STAGE_DATA}                 | ${'isLoadingStage'} | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}           | ${'isEmptyStage'}   | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}           | ${'isLoadingStage'} | ${false}
    ${types.REQUEST_CYCLE_ANALYTICS_DATA}       | ${'isLoading'}      | ${true}
    ${types.RECEIVE_GROUP_STAGES_ERROR}         | ${'stages'}         | ${[]}
    ${types.REQUEST_GROUP_STAGES}               | ${'stages'}         | ${[]}
    ${types.REQUEST_UPDATE_STAGE}               | ${'isLoading'}      | ${true}
    ${types.RECEIVE_UPDATE_STAGE_SUCCESS}       | ${'isLoading'}      | ${false}
    ${types.RECEIVE_UPDATE_STAGE_ERROR}         | ${'isLoading'}      | ${false}
    ${types.REQUEST_REMOVE_STAGE}               | ${'isLoading'}      | ${true}
    ${types.RECEIVE_REMOVE_STAGE_RESPONSE}      | ${'isLoading'}      | ${false}
    ${types.REQUEST_STAGE_MEDIANS}              | ${'medians'}        | ${{}}
    ${types.RECEIVE_STAGE_MEDIANS_ERROR}        | ${'medians'}        | ${{}}
    ${types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS} | ${'isLoading'}      | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation                       | payload                       | expectedState
    ${types.SET_FEATURE_FLAGS}     | ${{ hasDurationChart: true }} | ${{ featureFlags: { hasDurationChart: true } }}
    ${types.SET_SELECTED_GROUP}    | ${{ fullPath: 'cool-beans' }} | ${{ selectedGroup: { fullPath: 'cool-beans' }, selectedProjects: [] }}
    ${types.SET_SELECTED_PROJECTS} | ${selectedProjects}           | ${{ selectedProjects }}
    ${types.SET_DATE_RANGE}        | ${{ startDate, endDate }}     | ${{ startDate, endDate }}
    ${types.SET_SELECTED_STAGE}    | ${{ id: 'first-stage' }}      | ${{ selectedStage: { id: 'first-stage' } }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = {
        selectedGroup: { fullPath: 'rad-stage' },
      };
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS}`, () => {
    it('will set isLoading=false and errorCode=null', () => {
      mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, {
        stats: [],
        stages: [],
      });

      expect(state.errorCode).toBe(null);
      expect(state.isLoading).toBe(false);
    });
  });

  describe(`${types.RECEIVE_GROUP_STAGES_SUCCESS}`, () => {
    describe('with data', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_GROUP_STAGES_SUCCESS](state, customizableStagesAndEvents.stages);
      });

      it('will convert the stats object to stages', () => {
        [issueStage, planStage, codeStage, stagingStage, reviewStage, totalStage].forEach(stage => {
          expect(state.stages).toContainEqual(stage);
        });
      });
    });
  });

  describe(`${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR}`, () => {
    it('sets errorCode correctly', () => {
      const errorCode = 403;

      mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state, errorCode);

      expect(state.isLoading).toBe(false);
      expect(state.errorCode).toBe(errorCode);
    });
  });

  describe(`${types.RECEIVE_STAGE_MEDIANS_SUCCESS}`, () => {
    it('sets each id as a key in the median object with the corresponding value', () => {
      const stateWithData = {
        medians: {},
      };

      mutations[types.RECEIVE_STAGE_MEDIANS_SUCCESS](stateWithData, [
        { id: 1, value: 20 },
        { id: 2, value: 10 },
      ]);

      expect(stateWithData.medians).toEqual({ '1': 20, '2': 10 });
    });
  });

  describe(`${types.INITIALIZE_CYCLE_ANALYTICS}`, () => {
    const initialData = {
      group: { fullPath: 'cool-group' },
      selectedProjects,
      createdAfter: '2019-12-31',
      createdBefore: '2020-01-01',
    };

    it.each`
      stateKey              | expectedState
      ${'isLoading'}        | ${true}
      ${'selectedGroup'}    | ${initialData.group}
      ${'selectedProjects'} | ${initialData.selectedProjects}
      ${'startDate'}        | ${initialData.createdAfter}
      ${'endDate'}          | ${initialData.createdBefore}
    `(
      '$mutation with payload $payload will update state with $expectedState',
      ({ stateKey, expectedState }) => {
        state = {};
        mutations[types.INITIALIZE_CYCLE_ANALYTICS](state, initialData);

        expect(state[stateKey]).toEqual(expectedState);
      },
    );
  });
});

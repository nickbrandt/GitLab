import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import {
  summaryData,
  rawIssueEvents,
  issueEvents as transformedEvents,
  issueStage,
  planStage,
  codeStage,
  stagingStage,
  reviewStage,
  totalStage,
  groupLabels,
  startDate,
  endDate,
  customizableStagesAndEvents,
  tasksByTypeData,
  transformedDurationData,
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
    mutation                                       | stateKey                    | value
    ${types.HIDE_CUSTOM_STAGE_FORM}                | ${'isCreatingCustomStage'}  | ${false}
    ${types.SHOW_CUSTOM_STAGE_FORM}                | ${'isCreatingCustomStage'}  | ${true}
    ${types.EDIT_CUSTOM_STAGE}                     | ${'isEditingCustomStage'}   | ${true}
    ${types.REQUEST_STAGE_DATA}                    | ${'isLoadingStage'}         | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}              | ${'isEmptyStage'}           | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}              | ${'isLoadingStage'}         | ${false}
    ${types.REQUEST_CYCLE_ANALYTICS_DATA}          | ${'isLoading'}              | ${true}
    ${types.REQUEST_GROUP_LABELS}                  | ${'labels'}                 | ${[]}
    ${types.RECEIVE_GROUP_LABELS_ERROR}            | ${'labels'}                 | ${[]}
    ${types.RECEIVE_SUMMARY_DATA_ERROR}            | ${'summary'}                | ${[]}
    ${types.REQUEST_SUMMARY_DATA}                  | ${'summary'}                | ${[]}
    ${types.RECEIVE_GROUP_STAGES_AND_EVENTS_ERROR} | ${'stages'}                 | ${[]}
    ${types.REQUEST_GROUP_STAGES_AND_EVENTS}       | ${'stages'}                 | ${[]}
    ${types.RECEIVE_GROUP_STAGES_AND_EVENTS_ERROR} | ${'customStageFormEvents'}  | ${[]}
    ${types.REQUEST_GROUP_STAGES_AND_EVENTS}       | ${'customStageFormEvents'}  | ${[]}
    ${types.REQUEST_CREATE_CUSTOM_STAGE}           | ${'isSavingCustomStage'}    | ${true}
    ${types.RECEIVE_CREATE_CUSTOM_STAGE_RESPONSE}  | ${'isSavingCustomStage'}    | ${false}
    ${types.REQUEST_TASKS_BY_TYPE_DATA}            | ${'isLoadingChartData'}     | ${true}
    ${types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR}      | ${'isLoadingChartData'}     | ${false}
    ${types.REQUEST_UPDATE_STAGE}                  | ${'isLoading'}              | ${true}
    ${types.RECEIVE_UPDATE_STAGE_RESPONSE}         | ${'isLoading'}              | ${false}
    ${types.REQUEST_REMOVE_STAGE}                  | ${'isLoading'}              | ${true}
    ${types.RECEIVE_REMOVE_STAGE_RESPONSE}         | ${'isLoading'}              | ${false}
    ${types.REQUEST_DURATION_DATA}                 | ${'isLoadingDurationChart'} | ${true}
    ${types.RECEIVE_DURATION_DATA_ERROR}           | ${'isLoadingDurationChart'} | ${false}
    ${types.REQUEST_STAGE_MEDIANS}                 | ${'medians'}                | ${{}}
    ${types.RECEIVE_STAGE_MEDIANS_ERROR}           | ${'medians'}                | ${{}}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation                                       | payload                       | expectedState
    ${types.SET_FEATURE_FLAGS}                     | ${{ hasDurationChart: true }} | ${{ featureFlags: { hasDurationChart: true } }}
    ${types.SET_SELECTED_GROUP}                    | ${{ fullPath: 'cool-beans' }} | ${{ selectedGroup: { fullPath: 'cool-beans' }, selectedProjectIds: [] }}
    ${types.SET_SELECTED_PROJECTS}                 | ${[606, 707, 808, 909]}       | ${{ selectedProjectIds: [606, 707, 808, 909] }}
    ${types.SET_DATE_RANGE}                        | ${{ startDate, endDate }}     | ${{ startDate, endDate }}
    ${types.SET_SELECTED_STAGE}                    | ${{ id: 'first-stage' }}      | ${{ selectedStage: { id: 'first-stage' } }}
    ${types.UPDATE_SELECTED_DURATION_CHART_STAGES} | ${transformedDurationData}    | ${{ durationData: transformedDurationData }}
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

  describe(`${types.RECEIVE_STAGE_DATA_SUCCESS}`, () => {
    it('will set the currentStageEvents state item with the camelCased events', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state, rawIssueEvents);

      expect(state.currentStageEvents).toEqual(transformedEvents);
    });

    it('will set isLoadingStage=false', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state);

      expect(state.isLoadingStage).toEqual(false);
    });

    it('will set isEmptyStage=false if currentStageEvents.length > 0', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state, rawIssueEvents);

      expect(state.isEmptyStage).toEqual(false);
    });

    it('will set isEmptyStage=true if currentStageEvents.length <= 0', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state);

      expect(state.isEmptyStage).toEqual(true);
    });
  });

  describe.each`
    mutation                            | value
    ${types.REQUEST_GROUP_LABELS}       | ${[]}
    ${types.RECEIVE_GROUP_LABELS_ERROR} | ${[]}
  `('$mutation', ({ mutation, value }) => {
    it(`will set tasksByType.labelIds to ${value}`, () => {
      state = { tasksByType: {} };
      mutations[mutation](state);

      expect(state.tasksByType.labelIds).toEqual(value);
    });
  });

  describe(`${types.RECEIVE_GROUP_LABELS_SUCCESS}`, () => {
    it('will set the labels state item with the camelCased group labels', () => {
      mutations[types.RECEIVE_GROUP_LABELS_SUCCESS](state, groupLabels);

      expect(state.labels).toEqual(groupLabels.map(convertObjectPropsToCamelCase));
    });
  });

  describe(`${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS}`, () => {
    it('will set isLoading=false and errorCode=null', () => {
      mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, {
        stats: [],
        summary: [],
        stages: [],
      });

      expect(state.errorCode).toBe(null);
      expect(state.isLoading).toBe(false);
    });
  });

  describe(`${types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS}`, () => {
    describe('with data', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS](
          state,
          customizableStagesAndEvents,
        );
      });

      it('will convert the stats object to stages', () => {
        [issueStage, planStage, codeStage, stagingStage, reviewStage, totalStage].forEach(stage => {
          expect(state.stages).toContainEqual(stage);
        });
      });
    });
  });

  describe(`${types.RECEIVE_SUMMARY_DATA_SUCCESS}`, () => {
    beforeEach(() => {
      state = { stages: [{ slug: 'plan' }, { slug: 'issue' }, { slug: 'test' }] };
      mutations[types.RECEIVE_SUMMARY_DATA_SUCCESS](state, summaryData);
    });

    it('will set each summary item with a value of 0 to "-"', () => {
      expect(state.summary).toEqual([
        { value: '-', title: 'New Issues' },
        { value: '-', title: 'Deploys' },
      ]);
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

  describe(`${types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS}`, () => {
    it('sets isLoadingChartData to false', () => {
      mutations[types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, {});

      expect(state.isLoadingChartData).toEqual(false);
    });

    it('sets tasksByType.data to the raw returned chart data', () => {
      state = { tasksByType: { data: null } };
      mutations[types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, tasksByTypeData);

      expect(state.tasksByType.data).toEqual(tasksByTypeData);
    });
  });

  describe(`${types.RECEIVE_DURATION_DATA_SUCCESS}`, () => {
    it('sets the data correctly and falsifies isLoadingDurationChart', () => {
      const stateWithData = {
        isLoadingDurationChart: true,
        durationData: [['something', 'random']],
      };

      mutations[types.RECEIVE_DURATION_DATA_SUCCESS](stateWithData, transformedDurationData);

      expect(stateWithData.isLoadingDurationChart).toBe(false);
      expect(stateWithData.durationData).toBe(transformedDurationData);
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
});

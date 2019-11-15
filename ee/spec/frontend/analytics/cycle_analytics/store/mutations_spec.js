import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import {
  cycleAnalyticsData,
  rawEvents,
  issueEvents as transformedEvents,
  issueStage,
  planStage,
  codeStage,
  stagingStage,
  reviewStage,
  productionStage,
  groupLabels,
  startDate,
  endDate,
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
    mutation                                       | stateKey                   | value
    ${types.HIDE_CUSTOM_STAGE_FORM}                | ${'isAddingCustomStage'}   | ${false}
    ${types.SHOW_CUSTOM_STAGE_FORM}                | ${'isAddingCustomStage'}   | ${true}
    ${types.REQUEST_STAGE_DATA}                    | ${'isLoadingStage'}        | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}              | ${'isEmptyStage'}          | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}              | ${'isLoadingStage'}        | ${false}
    ${types.REQUEST_CYCLE_ANALYTICS_DATA}          | ${'isLoading'}             | ${true}
    ${types.REQUEST_GROUP_LABELS}                  | ${'labels'}                | ${[]}
    ${types.RECEIVE_GROUP_LABELS_ERROR}            | ${'labels'}                | ${[]}
    ${types.RECEIVE_SUMMARY_DATA_ERROR}            | ${'summary'}               | ${[]}
    ${types.REQUEST_SUMMARY_DATA}                  | ${'summary'}               | ${[]}
    ${types.RECEIVE_GROUP_STAGES_AND_EVENTS_ERROR} | ${'stages'}                | ${[]}
    ${types.REQUEST_GROUP_STAGES_AND_EVENTS}       | ${'stages'}                | ${[]}
    ${types.RECEIVE_GROUP_STAGES_AND_EVENTS_ERROR} | ${'customStageFormEvents'} | ${[]}
    ${types.REQUEST_GROUP_STAGES_AND_EVENTS}       | ${'customStageFormEvents'} | ${[]}
    ${types.REQUEST_CREATE_CUSTOM_STAGE}           | ${'isSavingCustomStage'}   | ${true}
    ${types.RECEIVE_CREATE_CUSTOM_STAGE_RESPONSE}  | ${'isSavingCustomStage'}   | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation                                   | payload                       | expectedState
    ${types.SET_CYCLE_ANALYTICS_DATA_ENDPOINT} | ${'cool-beans'}               | ${{ endpoints: { cycleAnalyticsStagesAndEvents: '/-/analytics/cycle_analytics/stages?group_id=cool-beans' } }}
    ${types.SET_STAGE_DATA_ENDPOINT}           | ${'rad-stage'}                | ${{ endpoints: { stageData: '/groups/rad-stage/-/cycle_analytics/events/rad-stage.json' } }}
    ${types.SET_SELECTED_GROUP}                | ${{ fullPath: 'cool-beans' }} | ${{ selectedGroup: { fullPath: 'cool-beans' }, selectedProjectIds: [] }}
    ${types.SET_SELECTED_PROJECTS}             | ${[606, 707, 808, 909]}       | ${{ selectedProjectIds: [606, 707, 808, 909] }}
    ${types.SET_DATE_RANGE}                    | ${{ startDate, endDate }}     | ${{ startDate, endDate }}
    ${types.SET_SELECTED_STAGE_ID}             | ${'first-stage'}              | ${{ selectedStageId: 'first-stage' }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = {
        endpoints: { cycleAnalyticsData: '/fake/api' },
        selectedGroup: { fullPath: 'rad-stage' },
      };
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.RECEIVE_STAGE_DATA_SUCCESS}`, () => {
    it('will set the currentStageEvents state item with the camelCased events', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state, { events: rawEvents });

      expect(state.currentStageEvents).toEqual(transformedEvents);
    });

    it('will set isLoadingStage=false', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state);

      expect(state.isLoadingStage).toEqual(false);
    });

    it('will set isEmptyStage=false if currentStageEvents.length > 0', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state, { events: rawEvents });

      expect(state.isEmptyStage).toEqual(false);
    });

    it('will set isEmptyStage=true if currentStageEvents.length <= 0', () => {
      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state);

      expect(state.isEmptyStage).toEqual(true);
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
        [issueStage, planStage, codeStage, stagingStage, reviewStage, productionStage].forEach(
          stage => {
            expect(state.stages).toContainEqual(stage);
          },
        );
      });

      it('will set the selectedStageId to the id of the first stage', () => {
        expect(state.selectedStageId).toEqual('issue');
      });
    });
  });

  describe(`${types.RECEIVE_SUMMARY_DATA_SUCCESS}`, () => {
    beforeEach(() => {
      state = { stages: [{ slug: 'plan' }, { slug: 'issue' }, { slug: 'test' }] };
      mutations[types.RECEIVE_SUMMARY_DATA_SUCCESS](state, {
        ...cycleAnalyticsData,
        summary: [{ value: 0, title: 'New Issues' }, { value: 0, title: 'Deploys' }],
        stats: [
          {
            name: 'issue',
            value: '1 day ago',
          },
          {
            name: 'plan',
            value: '6 months ago',
          },
          {
            name: 'test',
            value: null,
          },
        ],
      });
    });

    it('will set each summary item with a value of 0 to "-"', () => {
      expect(state.summary).toEqual([
        { value: '-', title: 'New Issues' },
        { value: '-', title: 'Deploys' },
      ]);
    });

    it('will set the median value for each stage', () => {
      expect(state.stages).toEqual([
        { slug: 'plan', value: '6 months ago' },
        { slug: 'issue', value: '1 day ago' },
        { slug: 'test', value: null },
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
});

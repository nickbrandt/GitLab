import { TEST_HOST } from 'helpers/test_constants';
import { getJSONFixture } from 'helpers/fixtures';
import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { DEFAULT_DAYS_IN_PAST } from 'ee/analytics/cycle_analytics/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { mockLabels } from '../../../../../spec/javascripts/vue_shared/components/sidebar/labels_select/mock_data';

/*
 * With the new API endpoints (analytics/cycle_analytics) we will
 * fetch stages, cycleEvents and summary data from different endpoints
 */
const endpoints = {
  cycleAnalyticsData: 'cycle_analytics/mock_data.json', // existing cycle analytics data
  customizableCycleAnalyticsStagesAndEvents: 'analytics/cycle_analytics/stages.json', // customizable stages and events endpoint
  stageEvents: stage => `cycle_analytics/events/${stage}.json`,
};

export const groupLabels = mockLabels.map(({ title, ...rest }) => ({ ...rest, name: title }));

export const group = {
  id: 1,
  name: 'foo',
  path: 'foo',
  full_path: 'foo',
  avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
};

const getStageById = (stages, id) => stages.find(stage => stage.id === id) || {};

export const cycleAnalyticsData = getJSONFixture(endpoints.cycleAnalyticsData);

export const customizableStagesAndEvents = getJSONFixture(
  endpoints.customizableCycleAnalyticsStagesAndEvents,
);

const dummyState = {};

// prepare the raw stage data for our components
mutations[types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS](dummyState, customizableStagesAndEvents);

export const issueStage = getStageById(dummyState.stages, 'issue');
export const planStage = getStageById(dummyState.stages, 'plan');
export const reviewStage = getStageById(dummyState.stages, 'review');
export const codeStage = getStageById(dummyState.stages, 'code');
export const testStage = getStageById(dummyState.stages, 'test');
export const stagingStage = getStageById(dummyState.stages, 'staging');
export const productionStage = getStageById(dummyState.stages, 'production');

export const allowedStages = [issueStage, planStage, codeStage];

const rawIssueEvents = getJSONFixture('cycle_analytics/events/issue.json');
export const rawEvents = rawIssueEvents.events;

const deepCamelCase = obj => convertObjectPropsToCamelCase(obj, { deep: true });

export const defaultStages = ['issue', 'plan', 'review', 'code', 'test', 'staging', 'production'];

const stageFixtures = defaultStages.reduce((acc, stage) => {
  const { events } = getJSONFixture(endpoints.stageEvents(stage));
  return {
    ...acc,
    [stage]: deepCamelCase(events),
  };
}, {});

export const endDate = new Date(2019, 0, 14);
export const startDate = getDateInPast(endDate, DEFAULT_DAYS_IN_PAST);

export const issueEvents = stageFixtures.issue;
export const planEvents = stageFixtures.plan;
export const reviewEvents = stageFixtures.review;
export const codeEvents = stageFixtures.code;
export const testEvents = stageFixtures.test;
export const stagingEvents = stageFixtures.staging;
export const productionEvents = stageFixtures.production;
export const rawCustomStage = {
  title: 'Coolest beans stage',
  hidden: false,
  legend: '',
  description: '',
  id: 18,
  custom: true,
  start_event_identifier: 'issue_first_mentioned_in_commit',
  end_event_identifier: 'issue_first_added_to_board',
};

const { events: rawCustomStageEvents } = customizableStagesAndEvents;
const camelCasedStageEvents = rawCustomStageEvents.map(deepCamelCase);

export const customStageStartEvents = camelCasedStageEvents.filter(ev => ev.canBeStartEvent);

// find get all the possible stop events
const allowedEndEventIds = new Set(customStageStartEvents.flatMap(e => e.allowedEndEvents));

export const customStageStopEvents = camelCasedStageEvents.filter(ev =>
  allowedEndEventIds.has(ev.identifier),
);

// TODO: the shim below should be removed once we have label events seeding
// https://gitlab.com/gitlab-org/gitlab/issues/33112
export const labelStartEvent = { ...customStageStartEvents[0], type: 'label' };
const firstAllowedStopEvent = labelStartEvent.allowedEndEvents[0];
// We need to enusre that the stop event can be applied to the start event
export const labelStopEvent = {
  ...customStageStopEvents.find(ev => ev.identifier === firstAllowedStopEvent),
  type: 'label',
};

export const customStageEvents = [
  ...customStageStartEvents.filter(ev => ev.identifier !== labelStartEvent.identifier),
  ...customStageStopEvents.filter(ev => ev.identifier !== labelStopEvent.identifier),
  labelStartEvent,
  labelStopEvent,
];

export const tasksByTypeData = getJSONFixture('analytics/type_of_work/tasks_by_type.json');

export const rawDurationData = [
  {
    duration_in_seconds: 1234000,
    finished_at: '2019-01-01T00:00:00.000Z',
  },
  {
    duration_in_seconds: 4321000,
    finished_at: '2019-01-02T00:00:00.000Z',
  },
];

export const transformedDurationData = [
  {
    slug: 'issue',
    selected: true,
    data: rawDurationData,
  },
  {
    slug: 'plan',
    selected: true,
    data: rawDurationData,
  },
];

export const flattenedDurationData = [
  { duration_in_seconds: 1234000, finished_at: '2019-01-01' },
  { duration_in_seconds: 4321000, finished_at: '2019-01-02' },
  { duration_in_seconds: 1234000, finished_at: '2019-01-01' },
  { duration_in_seconds: 4321000, finished_at: '2019-01-02' },
];

export const durationChartPlottableData = [
  ['2019-01-01', 29, '2019-01-01'],
  ['2019-01-02', 100, '2019-01-02'],
];

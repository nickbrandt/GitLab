import { TEST_HOST } from 'helpers/test_constants';
import { getJSONFixture } from 'helpers/fixtures';
import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { DEFAULT_DAYS_IN_PAST } from 'ee/analytics/cycle_analytics/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getDateInPast, getDatesInRange } from '~/lib/utils/datetime_utility';
import { mockLabels } from '../../../../../spec/javascripts/vue_shared/components/sidebar/labels_select/mock_data';
import { toYmd } from 'ee/analytics/shared/utils';

const endpoints = {
  customizableCycleAnalyticsStagesAndEvents: 'analytics/cycle_analytics/stages.json', // customizable stages and events endpoint
  stageEvents: stage => `analytics/cycle_analytics/stages/${stage}/records.json`,
  stageMedian: stage => `analytics/cycle_analytics/stages/${stage}/median.json`,
  summaryData: 'analytics/cycle_analytics/summary.json',
};

export const groupLabels = mockLabels.map(({ title, ...rest }) => ({ ...rest, name: title }));

export const group = {
  id: 1,
  name: 'foo',
  path: 'foo',
  full_path: 'foo',
  avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
};

const getStageByTitle = (stages, title) =>
  stages.find(stage => stage.title && stage.title.toLowerCase().trim() === title) || {};

export const summaryData = getJSONFixture(endpoints.summaryData);

export const customizableStagesAndEvents = getJSONFixture(
  endpoints.customizableCycleAnalyticsStagesAndEvents,
);

const dummyState = {};

// prepare the raw stage data for our components
mutations[types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS](dummyState, customizableStagesAndEvents);

export const issueStage = getStageByTitle(dummyState.stages, 'issue');
export const planStage = getStageByTitle(dummyState.stages, 'plan');
export const reviewStage = getStageByTitle(dummyState.stages, 'review');
export const codeStage = getStageByTitle(dummyState.stages, 'code');
export const testStage = getStageByTitle(dummyState.stages, 'test');
export const stagingStage = getStageByTitle(dummyState.stages, 'staging');
export const totalStage = getStageByTitle(dummyState.stages, 'total');

export const allowedStages = [issueStage, planStage, codeStage];

const deepCamelCase = obj => convertObjectPropsToCamelCase(obj, { deep: true });

export const defaultStages = ['issue', 'plan', 'review', 'code', 'test', 'staging', 'production'];

const stageFixtures = defaultStages.reduce((acc, stage) => {
  const events = getJSONFixture(endpoints.stageEvents(stage));
  return {
    ...acc,
    [stage]: events,
  };
}, {});

export const stageMedians = defaultStages.reduce((acc, stage) => {
  const { value } = getJSONFixture(endpoints.stageMedian(stage));
  return {
    ...acc,
    [stage]: value,
  };
}, {});

export const endDate = new Date(2019, 0, 14);
// Limit to just 5 days data for testing
export const startDate = getDateInPast(endDate, 4);

export const rawIssueEvents = stageFixtures.issue;
export const issueEvents = deepCamelCase(stageFixtures.issue);
export const planEvents = deepCamelCase(stageFixtures.plan);
export const reviewEvents = deepCamelCase(stageFixtures.review);
export const codeEvents = deepCamelCase(stageFixtures.code);
export const testEvents = deepCamelCase(stageFixtures.test);
export const stagingEvents = deepCamelCase(stageFixtures.staging);
export const totalEvents = deepCamelCase(stageFixtures.production);
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

export const medians = stageMedians;

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

const dateRange = getDatesInRange(startDate, endDate, toYmd);

export const tasksByTypeData = convertObjectPropsToCamelCase(
  getJSONFixture('analytics/type_of_work/tasks_by_type.json').map(labelData => {
    // add data points for our mock date range
    const maxValue = 10;
    const series = dateRange.map(date => [date, Math.floor(Math.random() * Math.floor(maxValue))]);
    return {
      ...labelData,
      series,
    };
  }),
  {
    deep: true,
  },
);

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
    slug: 1,
    selected: true,
    data: rawDurationData,
  },
  {
    slug: 2,
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

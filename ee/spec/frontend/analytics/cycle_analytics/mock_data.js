import { TEST_HOST } from 'helpers/test_constants';
import { getJSONFixture } from 'helpers/fixtures';
import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { DEFAULT_DAYS_IN_PAST } from 'ee/analytics/cycle_analytics/constants';
import { mockLabels } from '../../../../../spec/javascripts/vue_shared/components/sidebar/labels_select/mock_data';

export const groupLabels = mockLabels.map(({ title, ...rest }) => ({ ...rest, name: title }));

export const group = {
  id: 1,
  name: 'foo',
  path: 'foo',
  full_path: 'foo',
  avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
};

const getStageBySlug = (stages, slug) => stages.find(stage => stage.slug === slug) || {};

export const cycleAnalyticsData = getJSONFixture('cycle_analytics/mock_data.json');

const dummyState = {};

// prepare the raw stage data for our components
mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](dummyState, cycleAnalyticsData);

export const issueStage = getStageBySlug(dummyState.stages, 'issue');
export const planStage = getStageBySlug(dummyState.stages, 'plan');
export const reviewStage = getStageBySlug(dummyState.stages, 'review');
export const codeStage = getStageBySlug(dummyState.stages, 'code');
export const testStage = getStageBySlug(dummyState.stages, 'test');
export const stagingStage = getStageBySlug(dummyState.stages, 'staging');
export const productionStage = getStageBySlug(dummyState.stages, 'production');

export const allowedStages = [issueStage, planStage, codeStage];

const rawIssueEvents = getJSONFixture('cycle_analytics/events/issue.json');
export const rawEvents = rawIssueEvents.events;

const deepCamelCase = obj => convertObjectPropsToCamelCase(obj, { deep: true });

const defaultStages = ['issue', 'plan', 'review', 'code', 'test', 'staging', 'production'];
const stageFixtures = defaultStages.reduce((acc, stage) => {
  const { events } = getJSONFixture(`cycle_analytics/events/${stage}.json`);
  return {
    ...acc,
    [stage]: deepCamelCase(events),
  };
}, {});

export const endDate = new Date(Date.now());
export const startDate = getDateInPast(endDate, DEFAULT_DAYS_IN_PAST);

export const issueEvents = stageFixtures.issue;
export const planEvents = stageFixtures.plan;
export const reviewEvents = stageFixtures.review;
export const codeEvents = stageFixtures.code;
export const testEvents = stageFixtures.test;
export const stagingEvents = stageFixtures.staging;
export const productionEvents = stageFixtures.production;

const { events: rawCustomStageEvents } = getJSONFixture('analytics/cycle_analytics/stages.json');
const camelCasedStageEvents = rawCustomStageEvents.map(deepCamelCase);

export const customStageStartEvents = camelCasedStageEvents.filter(ev => ev.canBeStartEvent);
export const customStageStopEvents = camelCasedStageEvents.filter(ev => !ev.canBeStartEvent);

// TODO: the shim below should be removed once we have label events seeding
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

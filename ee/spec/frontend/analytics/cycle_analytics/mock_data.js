import { TEST_HOST } from 'helpers/test_constants';
import { getJSONFixture } from 'helpers/fixtures';
import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { mockLabels } from '../../../../../spec/javascripts/vue_shared/components/sidebar/labels_select/mock_data';

export const groupLabels = mockLabels.map(({ title, ...rest }) => ({ ...rest, name: title }));

export const group = {
  id: 1,
  name: 'foo',
  path: 'foo',
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

export const issueEvents = stageFixtures.issue;
export const planEvents = stageFixtures.plan;
export const reviewEvents = stageFixtures.review;
export const codeEvents = stageFixtures.code;
export const testEvents = stageFixtures.test;
export const stagingEvents = stageFixtures.staging;
export const productionEvents = stageFixtures.production;

const { events: rawCustomStageEvents } = getJSONFixture('analytics/cycle_analytics/stages.json');
export const customStageEvents = rawCustomStageEvents.map(deepCamelCase);

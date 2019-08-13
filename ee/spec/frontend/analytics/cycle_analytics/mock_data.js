import { TEST_HOST } from 'helpers/test_constants';
import { getJSONFixture } from 'helpers/fixtures';
import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

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

const apiResponse = {
  events: [
    {
      name: 'Issue created',
      identifier: 'issue_created',
      type: 'simple',
      can_be_start_event: true,
      allowed_end_events: ['issue_stage_end'],
    },
    {
      name: 'Issue first mentioned in a commit',
      identifier: 'issue_first_mentioned_in_commit',
      type: 'simple',
      can_be_start_event: false,
      allowed_end_events: [],
    },
    {
      name: 'Merge request created',
      identifier: 'merge_request_created',
      type: 'simple',
      can_be_start_event: true,
      allowed_end_events: ['merge_request_merged'],
    },

    {
      name: 'Merge request first deployed to production',
      identifier: 'merge_request_first_deployed_to_production',
      type: 'simple',
      can_be_start_event: false,
      allowed_end_events: [],
    },
    {
      name: 'Merge request last build finish time',
      identifier: 'merge_request_last_build_finished',
      type: 'simple',
      can_be_start_event: false,
      allowed_end_events: [],
    },
    {
      name: 'Merge request last build start time',
      identifier: 'merge_request_last_build_started',
      type: 'simple',
      can_be_start_event: true,
      allowed_end_events: ['merge_request_last_build_finished'],
    },
    {
      name: 'Merge request merged',
      identifier: 'merge_request_merged',
      type: 'simple',
      can_be_start_event: true,
      allowed_end_events: ['merge_request_first_deployed_to_production'],
    },
    {
      name: 'Issue first mentioned in a commit',
      identifier: 'code_stage_start',
      type: 'simple',
      can_be_start_event: true,
      allowed_end_events: ['merge_request_created'],
    },
    {
      name: 'Issue first associated with a milestone or issue first added to a board',
      identifier: 'issue_stage_end',
      type: 'simple',
      can_be_start_event: false,
      allowed_end_events: [],
    },
    {
      name: 'Issue first associated with a milestone or issue first added to a board',
      identifier: 'plan_stage_start',
      type: 'simple',
      can_be_start_event: true,
      allowed_end_events: ['issue_first_mentioned_in_commit'],
    },
    {
      identifier: 'issue_label_added',
      name: 'Issue Label Added',
      type: 'label',
      can_be_start_event: true,
      allowed_end_events: ['issue_closed', 'issue_label_removed'],
    },
    {
      identifier: 'issue_label_removed',
      name: 'Issue Label Removed',
      type: 'label',
      can_be_start_event: false,
      allowed_end_events: [],
    },
  ],
  stages: [
    {
      name: 'issue',
      legend: 'Related Issues',
      description: 'Time before an issue gets scheduled',
      id: 'issue',
      position: 1,
      hidden: false,
      custom: false,
      start_event_identifier: 'issue_created',
      end_event_identifier: 'issue_stage_end',
    },
    {
      name: 'plan',
      legend: 'Related Issues',
      description: 'Time before an issue starts implementation',
      id: 'plan',
      position: 2,
      hidden: false,
      custom: false,
      start_event_identifier: 'plan_stage_start',
      end_event_identifier: 'issue_first_mentioned_in_commit',
    },
    {
      name: 'code',
      legend: 'Related Merged Requests',
      description: 'Time until first merge request',
      id: 'code',
      position: 3,
      hidden: false,
      custom: false,
      start_event_identifier: 'code_stage_start',
      end_event_identifier: 'merge_request_created',
    },
    {
      name: 'test',
      legend: 'Related Merged Requests',
      description: 'Total test time for all commits/merges',
      id: 'test',
      position: 4,
      hidden: false,
      custom: false,
      start_event_identifier: 'merge_request_last_build_started',
      end_event_identifier: 'merge_request_last_build_finished',
    },
    {
      name: 'review',
      legend: 'Related Merged Requests',
      description: 'Time between merge request creation and merge/close',
      id: 'review',
      position: 5,
      hidden: false,
      custom: false,
      start_event_identifier: 'merge_request_created',
      end_event_identifier: 'merge_request_merged',
    },
    {
      name: 'staging',
      legend: 'Related Merged Requests',
      description: 'From merge request merge until deploy to production',
      id: 'staging',
      position: 6,
      hidden: false,
      custom: false,
      start_event_identifier: 'merge_request_merged',
      end_event_identifier: 'merge_request_first_deployed_to_production',
    },
    {
      name: 'production',
      legend: 'Related Merged Requests',
      description: 'From issue creation until deploy to production',
      id: 'production',
      position: 7,
      hidden: false,
      custom: false,
      start_event_identifier: 'merge_request_merged',
      end_event_identifier: 'merge_request_first_deployed_to_production',
    },
  ],
  summary: [
    {
      value: 2,
      title: 'New Issues',
    },
    {
      value: 0,
      title: 'Commits',
    },
    {
      value: 0,
      title: 'Deploys',
    },
  ],
  permissions: {
    issue: true,
    plan: true,
    code: true,
    test: true,
    review: true,
    staging: true,
    production: true,
  },
};

const rawEvents = [
  {
    name: 'Issue created',
    identifier: 'issue_created',
    type: 'simple',
    can_be_start_event: true,
    allowed_end_events: ['issue_closed', 'issue_merged'],
  },
  {
    name: 'Merge request closed',
    identifier: 'merge_request_closed',
    type: 'simple',
    can_be_start_event: false,
    allowed_end_events: [],
  },
  {
    name: 'Issue closed',
    identifier: 'issue_closed',
    type: 'simple',
    can_be_start_event: false,
    allowed_end_events: [],
  },
  {
    name: 'Issue merged',
    identifier: 'issue_merged',
    type: 'simple',
    can_be_start_event: false,
    allowed_end_events: [],
  },
];

export default {
  apiResponse,
  rawEvents,
};

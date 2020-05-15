import { __ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { gray10 } from '@gitlab/ui/scss_to_js/scss_variables';

export const PROJECTS_PER_PAGE = 50;

export const DEFAULT_DAYS_IN_PAST = 30;

export const EVENTS_LIST_ITEM_LIMIT = 50;

export const EMPTY_STAGE_TEXT = {
  issue: __(
    'The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.',
  ),
  plan: __(
    'The planning stage shows the time from the previous step to pushing your first commit. This time will be added automatically once you push your first commit.',
  ),
  code: __(
    'The coding stage shows the time from the first commit to creating the merge request. The data will automatically be added here once you create your first merge request.',
  ),
  test: __(
    'The testing stage shows the time GitLab CI takes to run every pipeline for the related merge request. The data will automatically be added after your first pipeline finishes running.',
  ),
  review: __(
    'The review stage shows the time from creating the merge request to merging it. The data will automatically be added after you merge your first merge request.',
  ),
  staging: __(
    'The staging stage shows the time between merging the MR and deploying code to the production environment. The data will be automatically added once you deploy to production for the first time.',
  ),
  production: __(
    'The production stage shows the total time it takes between creating an issue and deploying the code to production. The data will be automatically added once you have completed the full idea to production cycle.',
  ),
};

export const DEFAULT_STAGE_NAMES = [...Object.keys(EMPTY_STAGE_TEXT), 'total'];

export const TASKS_BY_TYPE_SUBJECT_ISSUE = 'Issue';
export const TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST = 'MergeRequest';
export const TASKS_BY_TYPE_MAX_LABELS = 15;
export const PATH_BACKGROUND_COLOR = gray10;

export const TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS = {
  [TASKS_BY_TYPE_SUBJECT_ISSUE]: __('Issues'),
  [TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST]: __('Merge Requests'),
};

export const TASKS_BY_TYPE_FILTERS = {
  SUBJECT: 'SUBJECT',
  LABEL: 'LABEL',
};

export const STAGE_ACTIONS = {
  SELECT: 'selectStage',
  EDIT: 'editStage',
  REMOVE: 'removeStage',
  HIDE: 'hideStage',
  CREATE: 'createStage',
  UPDATE: 'updateStage',
};

export const STAGE_NAME = {
  TOTAL: 'total',
  PRODUCTION: 'production',
  OVERVIEW: 'overview',
};

/**
 * An object containing capitalized stages names
 * i.e. { TOTAL: 'total' } => { TOTAL: 'Total' }
 */
export const CAPITALIZED_STAGE_NAME = Object.keys(STAGE_NAME).reduce((acc, stage) => {
  return {
    ...acc,
    [stage]: capitalizeFirstCharacter(STAGE_NAME[stage]),
  };
}, {});

export const PATH_HOME_ICON = 'home';

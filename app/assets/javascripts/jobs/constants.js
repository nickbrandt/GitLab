import { __, s__ } from '~/locale';

const cancel = __('Cancel');

export const JOBS_SIDEBAR = {
  cancel,
  debug: __('Debug'),
  newIssue: __('New issue'),
  retry: __('Retry'),
  toggleSidebar: __('Toggle Sidebar'),
};

export const JOBS_RETRY_FORWARD_DEPLOYMENT_MODAL = {
  cancel,
  body: s__(
    `Jobs|You're about to retry a job that failed because it attempted to deploy code that is older than the latest deployment. Retrying this job could result in overwriting the environment with the older source code. Are you sure you want to proceed?`,
  ),
  primaryText: __('Retry job'),
  title: s__('Jobs|Are you sure you want to retry this job?'),
};

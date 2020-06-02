import { s__ } from '~/locale';

export const ALL = 'all';

export const BASE_FILTERS = {
  severity: {
    name: s__('ciReport|All severities'),
    id: ALL,
  },
  report_type: {
    name: s__('ciReport|All report types'),
    id: ALL,
  },
  project_id: {
    name: s__('ciReport|All projects'),
    id: ALL,
  },
};

import { __, s__ } from '~/locale';

export const SORT_FIELDS = {
  name: s__('Dependencies|Component name'),
  packager: s__('Dependencies|Packager'),
};

export const SORT_FIELDS_WITH_SEVERITY = {
  ...SORT_FIELDS,
  severity: s__('Vulnerability|Severity'),
};

export const SORT_ORDER = {
  ascending: 'asc',
  descending: 'desc',
};

export const REPORT_STATUS = {
  ok: 'ok',
  jobNotSetUp: 'job_not_set_up',
  jobFailed: 'job_failed',
  noDependencies: 'no_dependencies',
  incomplete: 'no_dependency_files',
};

export const FETCH_ERROR_MESSAGE = __(
  'Error fetching the dependency list. Please check your network connection and try again.',
);

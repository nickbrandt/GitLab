import { __ } from '~/locale';

export const LIST_TYPE = {
  ISSUE_LIST: 'issue_list',
  SERVICE_DESK: 'service_desk',
  JIRA: 'jira',
};

// Maps sort order as it appears in the URL query to API `order_by` and `sort` params.
const PRIORITY = 'priority';
const ASC = 'asc';
const DESC = 'desc';
const CREATED_AT = 'created_at';
const UPDATED_AT = 'updated_at';
const DUE_DATE = 'due_date';
const MILESTONE_DUE = 'milestone_due';
const POPULARITY = 'popularity';
const WEIGHT = 'weight';
const LABEL_PRIORITY = 'label_priority';
export const RELATIVE_POSITION = 'relative_position';
export const LOADING_LIST_ITEMS_LENGTH = 8;
export const PAGE_SIZE = 20;
export const PAGE_SIZE_MANUAL = 100;

export const sortOrderMap = {
  priority: { order_by: PRIORITY, sort: ASC }, // asc and desc are flipped for some reason
  created_date: { order_by: CREATED_AT, sort: DESC },
  created_asc: { order_by: CREATED_AT, sort: ASC },
  updated_desc: { order_by: UPDATED_AT, sort: DESC },
  updated_asc: { order_by: UPDATED_AT, sort: ASC },
  milestone_due_desc: { order_by: MILESTONE_DUE, sort: DESC },
  milestone: { order_by: MILESTONE_DUE, sort: ASC },
  due_date_desc: { order_by: DUE_DATE, sort: DESC },
  due_date: { order_by: DUE_DATE, sort: ASC },
  popularity: { order_by: POPULARITY, sort: DESC },
  popularity_asc: { order_by: POPULARITY, sort: ASC },
  label_priority: { order_by: LABEL_PRIORITY, sort: ASC }, // asc and desc are flipped
  relative_position: { order_by: RELATIVE_POSITION, sort: ASC },
  weight_desc: { order_by: WEIGHT, sort: DESC },
  weight: { order_by: WEIGHT, sort: ASC },
};

const sortOptions = {
  priority: {
    title: __('Priority'),
  },
  created_at: {
    title: __('Created date'),
    sortDirection: {
      descending: 'created_desc',
      ascending: 'created_asc',
    },
  },
  updated_at: {
    title: __('Last updated'),
    sortDirection: {
      descending: 'updated_desc',
      ascending: 'updated_asc',
    },
  },
  milestone_due: {
    title: __('Milestone due date'),
    sortDirections: {
      descending: 'milestone_due_desc',
      ascending: 'milestone_due_asc',
    },
  },
  due_date: {
    title: __('Due date'),
    sortDirections: {
      descending: 'due_date_desc',
      ascending: 'due_date_asc',
    },
  },
  popularity: {
    title: __('Popularity'),
    sortDirections: {
      descending: 'popularity_desc',
      ascending: 'popularity_asc',
    },
  },
  label_priority: {
    title: __('Label priority'),
  },
  relative_position: {
    title: __('Manual'),
  },
};

/**
 * Flattens an array of sortOptions and assigns enumerated Id to each element.
 *
 * @param {{ title: string, sortDirections?: Object }[]} selectedSortOptions - Array of sortOptions.
 * @returns {{ id: number, title: string, sortDirections?: Object }[]}
 */
function assignIndex(selectedSortOptions) {
  return selectedSortOptions.map((elem, index) => {
    return {
      id: index,
      ...elem,
    };
  });
}

export const AVAILABLE_SORT_OPTIONS = {
  [LIST_TYPE.JIRA]: assignIndex([sortOptions.created_at, sortOptions.updated_at]),
  [LIST_TYPE.ISSUE_LIST]: assignIndex([
    sortOptions.priority,
    sortOptions.created_at,
    sortOptions.updated_at,
    sortOptions.milestone_due,
    sortOptions.due_date,
    sortOptions.popularity,
    sortOptions.label_priority,
    sortOptions.relative_position,
  ]),
};

export const JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY = 'jira-import-success-alert-hide-map';

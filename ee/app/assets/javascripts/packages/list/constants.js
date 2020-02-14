import { __ } from '~/locale';

export const FETCH_PACKAGES_LIST_ERROR_MESSAGE = __(
  'Something went wrong while fetching the packages list.',
);
export const FETCH_PACKAGE_ERROR_MESSAGE = __('Something went wrong while fetching the package.');
export const DELETE_PACKAGE_ERROR_MESSAGE = __('Something went wrong while deleting the package.');
export const DELETE_PACKAGE_SUCCESS_MESSAGE = __('Package deleted successfully');

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 20;

export const GROUP_PAGE_TYPE = 'groups';

export const LIST_KEY_NAME = 'name';
export const LIST_KEY_PROJECT = 'project_path';
export const LIST_KEY_VERSION = 'version';
export const LIST_KEY_PACKAGE_TYPE = 'package_type';
export const LIST_KEY_CREATED_AT = 'created_at';
export const LIST_KEY_ACTIONS = 'actions';

export const LIST_LABEL_NAME = __('Name');
export const LIST_LABEL_PROJECT = __('Project');
export const LIST_LABEL_VERSION = __('Version');
export const LIST_LABEL_PACKAGE_TYPE = __('Type');
export const LIST_LABEL_CREATED_AT = __('Created');
export const LIST_LABEL_ACTIONS = '';

export const LIST_ORDER_BY_PACKAGE_TYPE = 'type';

export const ASCENDING_ODER = 'asc';
export const DESCENDING_ORDER = 'desc';

// The following is not translated because it is used to build a JavaScript exception error message
export const MISSING_DELETE_PATH_ERROR = 'Missing delete_api_path link';

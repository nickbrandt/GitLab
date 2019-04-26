import { s__ } from '~/locale';

export const SORT_FIELDS = {
  name: s__('Dependencies|Component name'),
  type: s__('Dependencies|Packager'),
};

export const SORT_ORDER = {
  ascending: 'asc',
  descending: 'desc',
};

export const PACKAGE_TYPES = {
  gem: s__('Dependencies|Bundler (Ruby)'),
  pypi: s__('Dependencies|Pip (Python)'),
  maven: s__('Dependencies|Maven (Java)'),
  composer: s__('Dependencies|Composer (PHP)'),
  npm: s__('Dependencies|npm (JavaScript)'),
};

export const REPORT_STATUS = {
  notSetUp: 'file_not_found',
};

export const FETCH_ERROR_MESSAGE = s__(
  'Dependencies|Error fetching the Bill of Materials. Please check your network connection and try again.',
);

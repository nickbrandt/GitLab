import { s__ } from '~/locale';
import { FILTER } from './modules/list/constants';

// eslint-disable-next-line import/prefer-default-export
export const DEPENDENCY_LIST_TYPES = {
  all: {
    namespace: 'allDependencies',
    label: s__('Dependencies|All'),
    initialState: {
      filter: FILTER.all,
    },
  },
  vulnerable: {
    namespace: 'vulnerableDependencies',
    label: s__('Dependencies|Vulnerable components'),
    initialState: {
      filter: FILTER.vulnerable,
    },
  },
};

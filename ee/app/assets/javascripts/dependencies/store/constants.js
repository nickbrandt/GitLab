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
};

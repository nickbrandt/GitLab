<<<<<<< HEAD
import { REST, GRAPHQL } from './constants';

export const accessors = {
  [REST]: {
    groupId: 'id',
  },
  [GRAPHQL]: {
    groupId: 'name',
  },
};
=======
import { get } from 'lodash';
import { REST, GRAPHQL } from './constants';

const accessors = {
  [REST]: {
    detailsPath: 'details_path',
    groupId: 'id',
    hasDetails: 'has_details',
    pipelineStatus: ['details', 'status'],
    sourceJob: ['source_job', 'name'],
  },
  [GRAPHQL]: {
    detailsPath: 'detailsPath',
    groupId: 'name',
    hasDetails: 'hasDetails',
    pipelineStatus: 'status',
    sourceJob: ['sourceJob', 'name'],
  },
};

const accessValue = (dataMethod, prop, item) => {
  return get(item, accessors[dataMethod][prop]);
};

export { accessors, accessValue };
>>>>>>> 5a4bf1b75d7 (Changes for accessors)

import * as types from './mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const setPaths = ({ commit }, { milestonesPath = '', labelsPath = '' }) => {
  commit(types.SET_MILESTONES_PATH, milestonesPath);
  commit(types.SET_LABELS_PATH, labelsPath);
};

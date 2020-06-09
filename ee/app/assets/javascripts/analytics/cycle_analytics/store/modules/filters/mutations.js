import * as types from './mutation_types';

export default {
  [types.SET_MILESTONES_PATH](state, milestonesPath) {
    state.milestonesPath = milestonesPath;
  },
  [types.SET_LABELS_PATH](state, labelsPath) {
    state.labelsPath = labelsPath;
  },
};

import * as types from './mutation_types';

export const setProjectId = ({ commit }, projectId) => commit(types.SET_PROJECT_ID, projectId);

export const setFilters = ({ commit }, { label_name, milestone_title }) => {
  commit(types.SET_FILTERS, { labelName: label_name, milestoneTitle: milestone_title });
};

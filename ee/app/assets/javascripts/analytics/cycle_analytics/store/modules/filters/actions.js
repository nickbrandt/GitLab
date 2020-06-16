import * as types from './mutation_types';

const appendExtension = path => (path.indexOf('.') > -1 ? path : `${path}.json`);

export const setPaths = ({ commit }, { milestonesPath = '', labelsPath = '' }) => {
  commit(types.SET_MILESTONES_PATH, appendExtension(milestonesPath));
  commit(types.SET_LABELS_PATH, appendExtension(labelsPath));
};

export const setFilters = ({ dispatch, state }, params) => {
  const { selectedLabels: labelNames = [], ...rest } = params;
  const {
    labels: { data: labelsList = [] },
  } = state;

  const selectedLabels = labelsList.filter(({ title }) => labelNames.includes(title));
  const nextFilters = {
    ...rest,
    selectedLabels,
  };

  return dispatch('setSelectedFilters', nextFilters, { root: true });
};

import * as types from './mutation_types';

export default {
  [types.SET_LOADING_STATE](state, value) {
    state.loading = value;
  },
  [types.SET_CLUSTERS_DATA](state, data) {
    const clusters = data.clusters || []
    const clustersPerPage = Number(data.per_page) || 1
    const currentPage = Number(data.currentPage) || 1
    const totalCount = Number(data.totalCount) || 0
    const totalPages = Number(data.totalPages) || 0

    Object.assign(state, {
      clusters,
      clustersPerPage,
      currentPage,
      totalCount,
      totalPages
    });
  },
};

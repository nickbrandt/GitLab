import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import createFlash from '~/flash';
import { FETCH_ERROR_MESSAGE } from './constants';
import { isDependenciesList, hasReportStatus } from './utils';
import * as types from './mutation_types';
import realAxios from '~/lib/utils/axios_utils';
import mockAxios from './mock_axios';

// TODO: remove mock-axios once the backend implementation is actually
// available
let axios;
if (process.env.NODE_ENV === 'test') {
  axios = realAxios;
} else {
  axios = mockAxios;
}

export const setDependenciesEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_DEPENDENCIES_ENDPOINT, endpoint);

export const setDependenciesDownloadEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_DEPENDENCIES_DOWNLOAD_ENDPOINT, endpoint);

export const requestDependencies = ({ commit }) => commit(types.REQUEST_DEPENDENCIES);

export const receiveDependenciesSuccess = ({ commit }, { headers, data }) => {
  if (isDependenciesList(data)) {
    const normalizedHeaders = normalizeHeaders(headers);
    const pageInfo = parseIntPagination(normalizedHeaders);
    const dependencies = data;

    commit(types.RECEIVE_DEPENDENCIES_SUCCESS, { dependencies, pageInfo });
  } else if (hasReportStatus(data)) {
    commit(types.SET_REPORT_STATUS, data.report_status);
  }
};

export const receiveDependenciesError = ({ commit }, error) =>
  commit(types.RECEIVE_DEPENDENCIES_ERROR, error);

export const fetchDependencies = ({ state, dispatch }, params = {}) => {
  if (!state.endpoint) {
    return;
  }

  dispatch('requestDependencies');

  axios
    .get(state.endpoint, {
      params: {
        sort_by: state.sortField,
        sort: state.sortOrder,
        ...params,
      },
    })
    .then(response => {
      const { data } = response;
      if (isDependenciesList(data) || hasReportStatus(data)) {
        dispatch('receiveDependenciesSuccess', response);
      } else {
        throw new Error('Invalid server response');
      }
    })
    .catch(error => {
      dispatch('receiveDependenciesError', error);
      createFlash(FETCH_ERROR_MESSAGE);
    });
};

export const setSortField = ({ commit, dispatch }, id) => {
  commit(types.SET_SORT_FIELD, id);
  dispatch('fetchDependencies');
};

export const toggleSortOrder = ({ commit, dispatch }) => {
  commit(types.TOGGLE_SORT_ORDER);
  dispatch('fetchDependencies');
};

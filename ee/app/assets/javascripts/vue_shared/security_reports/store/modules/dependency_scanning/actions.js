import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const setHeadPath = ({ commit }, path) => commit(types.SET_HEAD_PATH, path);

export const setBasePath = ({ commit }, path) => commit(types.SET_BASE_PATH, path);

export const requestReports = ({ commit }) => commit(types.REQUEST_REPORTS);

export const receiveReports = ({ commit }, response) => commit(types.RECEIVE_REPORTS, response);

export const receiveError = ({ commit }, error) => commit(types.RECEIVE_REPORTS_ERROR, error);

export const fetchReports = ({ state, rootState, dispatch }) => {
  const { base, head } = state.paths;
  const { blobPath, vulnerabilityFeedbackPath } = rootState;

  dispatch('requestReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
    axios.get(vulnerabilityFeedbackPath, {
      params: {
        category: 'dependency_scanning',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveReports', {
        reports: {
          head: values && values[0] ? values[0].data : null,
          base: values && values[1] ? values[1].data : null,
          enrichData: values && values[2] ? values[2].data : [],
        },
        blobPath,
      });
    })
    .catch(() => {
      dispatch('receiveError');
    });
};

export const updateVulnerability = ({ commit }, vulnerability) =>
  commit(types.UPDATE_VULNERABILITY, vulnerability);

export default () => {};

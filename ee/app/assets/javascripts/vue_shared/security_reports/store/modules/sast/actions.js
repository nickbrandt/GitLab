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
        category: 'sast',
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

export const setHeadReportEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_HEAD_REPORT_ENDPOINT, endpoint);

export const fetchHeadReport = ({ state, dispatch }) => {
  dispatch('requestHeadReport');

  axios
    .get(state.headReportEndpoint, {
      params: {
        report_type: 'sast',
      },
    })
    .then(({ data, headers }) => {
      const count = headers ? headers['x-total'] : 0;

      dispatch('receiveHeadReportSuccess', { data, count });
    })
    .catch(() => {
      dispatch('receiveHeadReportError');
    });
};

export const requestHeadReport = ({ commit }) => {
  commit(types.REQUEST_HEAD_REPORT);
};

export const receiveHeadReportSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_HEAD_REPORT_SUCCESS, payload);
};

export const receiveHeadReportError = ({ commit }) => {
  commit(types.RECEIVE_HEAD_REPORT_ERROR);
};

export default () => {};

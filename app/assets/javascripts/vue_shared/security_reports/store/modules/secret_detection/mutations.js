import Vue from 'vue';
import { parseDiff } from '~/vue_shared/security_reports/store/utils';
import * as types from './mutation_types';

export default {
  [types.SET_SECRET_SCANNING_DIFF_ENDPOINT](state, path) {
    Vue.set(state.paths, 'diffEndpoint', path);
  },

  [types.REQUEST_SECRET_SCANNING_DIFF](state) {
    Vue.set(state, 'isLoading', true);
  },

  [types.RECEIVE_SECRET_SCANNING_DIFF_SUCCESS](state, { diff, enrichData }) {
    const { added, fixed, existing } = parseDiff(diff, enrichData);
    const baseReportOutofDate = diff.base_report_out_of_date || false;
    const hasBaseReport = Boolean(diff.base_report_created_at);

    Vue.set(state, 'isLoading', false);
    Vue.set(state, 'newIssues', added);
    Vue.set(state, 'resolvedIssues', fixed);
    Vue.set(state, 'allIssues', existing);
    Vue.set(state, 'baseReportOutofDate', baseReportOutofDate);
    Vue.set(state, 'hasBaseReport', hasBaseReport);
  },

  [types.RECEIVE_SECRET_SCANNING_DIFF_ERROR](state) {
    Vue.set(state, 'isLoading', false);
    Vue.set(state, 'hasError', true);
  },
};

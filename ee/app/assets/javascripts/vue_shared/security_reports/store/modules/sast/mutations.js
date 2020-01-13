import Vue from 'vue';
import * as types from './mutation_types';
import { parseSastIssues, findIssueIndex, parseDiff } from '../../utils';
import filterByKey from '../../utils/filter_by_key';

export default {
  [types.SET_HEAD_PATH](state, path) {
    Vue.set(state.paths, 'head', path);
  },

  [types.SET_BASE_PATH](state, path) {
    Vue.set(state.paths, 'base', path);
  },

  [types.SET_DIFF_ENDPOINT](state, path) {
    Vue.set(state.paths, 'diffEndpoint', path);
  },

  [types.REQUEST_REPORTS](state) {
    state.isLoading = true;
  },

  /**
   * Compares sast results and returns the formatted report
   *
   * Sast has 3 types of issues: newIssues, resolvedIssues and allIssues.
   *
   * When we have both base and head:
   * - newIssues = head - base
   * - resolvedIssues = base - head
   * - allIssues = head - newIssues - resolvedIssues
   *
   * When we only have head
   * - newIssues = head
   * - resolvedIssues = 0
   * - allIssues = 0
   */
  [types.RECEIVE_REPORTS](state, payload) {
    const { reports, blobPath } = payload;

    if (reports.base && reports.head) {
      const filterKey = 'cve';
      const parsedHead = parseSastIssues(reports.head, reports.enrichData, blobPath.head);
      const parsedBase = parseSastIssues(reports.base, reports.enrichData, blobPath.base);

      const newIssues = filterByKey(parsedHead, parsedBase, filterKey);
      const resolvedIssues = filterByKey(parsedBase, parsedHead, filterKey);
      const allIssues = filterByKey(parsedHead, newIssues.concat(resolvedIssues), filterKey);

      state.newIssues = newIssues;
      state.resolvedIssues = resolvedIssues;
      state.allIssues = allIssues;
      state.isLoading = false;
    } else if (reports.head && !reports.base) {
      const newIssues = parseSastIssues(reports.head, reports.enrichData, blobPath.head);

      state.newIssues = newIssues;
      state.isLoading = false;
    }
  },

  [types.RECEIVE_DIFF_SUCCESS](state, { diff, enrichData }) {
    const { added, fixed, existing } = parseDiff(diff, enrichData);
    const baseReportOutofDate = diff.base_report_out_of_date || false;

    state.isLoading = false;
    state.newIssues = added;
    state.resolvedIssues = fixed;
    state.allIssues = existing;
    state.baseReportOutofDate = baseReportOutofDate;
  },

  [types.RECEIVE_DIFF_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },

  [types.RECEIVE_REPORTS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },

  [types.UPDATE_VULNERABILITY](state, issue) {
    const newIssuesIndex = findIssueIndex(state.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
      return;
    }

    const allIssuesIndex = findIssueIndex(state.allIssues, issue);
    if (allIssuesIndex !== -1) {
      state.allIssues.splice(allIssuesIndex, 1, issue);
    }
  },
};

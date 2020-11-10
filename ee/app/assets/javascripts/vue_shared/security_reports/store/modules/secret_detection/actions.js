import * as types from './mutation_types';

export * from '~/vue_shared/security_reports/store/modules/secret_detection/actions';

export const updateSecretScanningIssue = ({ commit }, issue) =>
  commit(types.UPDATE_SECRET_SCANNING_ISSUE, issue);

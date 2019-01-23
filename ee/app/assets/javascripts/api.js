import CEApi from '~/api';
import axios from '~/lib/utils/axios_utils';

export default {
  ...CEApi,
  projectApprovalSettingsPath: '/api/:version/projects/:id/approval_settings',
  projectApprovalRulesPath: '/api/:version/projects/:id/approval_settings/rules',
  projectApprovalRulePath: '/api/:version/projects/:id/approval_settings/rules/:ruleid',
  getProjectApprovalSettings(projectId) {
    const url = this.buildUrl(this.projectApprovalSettingsPath).replace(
      ':id',
      encodeURIComponent(projectId),
    );

    return axios.get(url);
  },

  putProjectApprovalSettings(projectId, settings) {
    const url = this.buildUrl(this.projectApprovalSettingsPath).replace(
      ':id',
      encodeURIComponent(projectId),
    );

    return axios.put(url, settings);
  },

  getProjectApprovalRules(projectId) {
    const url = this.buildUrl(this.projectApprovalRulesPath).replace(
      ':id',
      encodeURIComponent(projectId),
    );

    return axios.get(url);
  },

  postProjectApprovalRule(projectId, rule) {
    const url = this.buildUrl(this.projectApprovalRulesPath).replace(
      ':id',
      encodeURIComponent(projectId),
    );

    return axios.post(url, rule);
  },

  putProjectApprovalRule(projectId, ruleId, rule) {
    const url = this.buildUrl(this.projectApprovalRulePath)
      .replace(':id', encodeURIComponent(projectId))
      .replace(':ruleid', encodeURIComponent(ruleId));

    return axios.put(url, rule);
  },

  deleteProjectApprovalRule(projectId, ruleId) {
    const url = this.buildUrl(this.projectApprovalRulePath)
      .replace(':id', encodeURIComponent(projectId))
      .replace(':ruleid', encodeURIComponent(ruleId));

    return axios.delete(url);
  },
};

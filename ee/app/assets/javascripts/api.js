import CEApi from '~/api';
import axios from '~/lib/utils/axios_utils';

export default {
  ...CEApi,
  projectApprovalRulesPath: '/api/:version/projects/:id/approval_rules',
  projectApprovalRulePath: '/api/:version/projects/:id/approval_rules/:ruleid',
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

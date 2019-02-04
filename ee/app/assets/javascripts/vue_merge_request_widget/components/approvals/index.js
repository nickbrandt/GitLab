import MultipleRuleApprovals from './multiple_rule/approvals.vue';
import SingleRuleApprovals from './single_rule/approvals.vue';

export default (gon.features.approvalRules ? MultipleRuleApprovals : SingleRuleApprovals);

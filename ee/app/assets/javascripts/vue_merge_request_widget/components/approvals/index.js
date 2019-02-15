import MultipleRuleApprovals from './multiple_rule/approvals.vue';
import SingleRuleApprovals from './single_rule/approvals.vue';

export default {
  functional: true,
  render(h, context) {
    const component = gon.features.approvalRules ? MultipleRuleApprovals : SingleRuleApprovals;
    return h(component, context.data, context.children);
  },
};

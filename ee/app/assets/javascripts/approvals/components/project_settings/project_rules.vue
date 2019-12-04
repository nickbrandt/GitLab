<script>
import { mapState, mapActions } from 'vuex';
import { n__, sprintf } from '~/locale';
import { RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR } from '../../constants';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import ApprovalCheckRulePopover from '../approval_check_rule_popover.vue';
import Rules from '../rules.vue';
import RuleControls from '../rule_controls.vue';
import EmptyRule from '../mr_edit/empty_rule.vue';
import RuleInput from '../mr_edit/rule_input.vue';

export default {
  components: {
    Icon,
    RuleControls,
    Rules,
    UserAvatarList,
    ApprovalCheckRulePopover,
    EmptyRule,
    RuleInput,
  },
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: state => state.approvals.rules,
    }),
    hasNamedRule() {
      return this.rules.some(rule => rule.ruleType === RULE_TYPE_REGULAR);
    },
    hasAnyRule() {
      return (
        this.settings.allowMultiRule &&
        !this.rules.some(rule => rule.ruleType === RULE_TYPE_ANY_APPROVER)
      );
    },
  },
  watch: {
    rules: {
      handler(newValue) {
        if (
          this.settings.allowMultiRule &&
          !newValue.some(rule => rule.ruleType === RULE_TYPE_ANY_APPROVER)
        ) {
          this.addEmptyRule();
        }
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['addEmptyRule']),
    summaryText(rule) {
      return this.settings.allowMultiRule
        ? this.summaryMultipleRulesText(rule)
        : this.summarySingleRuleText(rule);
    },
    membersCountText(rule) {
      return n__(
        'ApprovalRuleSummary|%d member',
        'ApprovalRuleSummary|%d members',
        rule.approvers.length,
      );
    },
    summarySingleRuleText(rule) {
      const membersCount = this.membersCountText(rule);

      return sprintf(
        n__(
          'ApprovalRuleSummary|%{count} approval required from %{membersCount}',
          'ApprovalRuleSummary|%{count} approvals required from %{membersCount}',
          rule.approvalsRequired,
        ),
        { membersCount, count: rule.approvalsRequired },
      );
    },
    summaryMultipleRulesText(rule) {
      return sprintf(
        n__(
          '%{count} approval required from %{name}',
          '%{count} approvals required from %{name}',
          rule.approvalsRequired,
        ),
        { name: rule.name, count: rule.approvalsRequired },
      );
    },
    canEdit(rule) {
      const { canEdit, allowMultiRule } = this.settings;

      return canEdit && (!allowMultiRule || !rule.hasSource);
    },
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead" slot-scope="{ name, members, approvalsRequired }">
      <tr class="d-none d-sm-table-row">
        <th class="w-25">{{ hasNamedRule ? name : members }}</th>
        <th :class="settings.allowMultiRule ? 'w-50 d-none d-sm-table-cell' : 'w-75'">
          <span v-if="hasNamedRule">{{ members }}</span>
        </th>
        <th>{{ approvalsRequired }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tbody" slot-scope="{ rules }">
      <template v-for="(rule, index) in rules">
        <empty-rule
          v-if="rule.ruleType === 'any_approver'"
          :key="index"
          :rule="rule"
          :allow-multi-rule="settings.allowMultiRule"
          :is-mr-edit="false"
          :eligible-approvers-docs-path="settings.eligibleApproversDocsPath"
          :can-edit="canEdit(rule)"
        />
        <tr v-else :key="index">
          <td class="js-name">
            {{ rule.name }}
          </td>
          <td class="js-members" :class="settings.allowMultiRule ? 'd-none d-sm-table-cell' : null">
            <user-avatar-list :items="rule.approvers" :img-size="24" empty-text="" />
          </td>
          <td class="js-approvals-required">
            <rule-input :rule="rule" />
          </td>
          <td class="text-nowrap px-2 w-0 js-controls">
            <rule-controls v-if="canEdit(rule)" :rule="rule" />
          </td>
        </tr>
      </template>
    </template>
  </rules>
</template>

<script>
import { mapState } from 'vuex';
import { n__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from '../rules.vue';
import RuleControls from '../rule_controls.vue';

export default {
  components: {
    Icon,
    UserAvatarList,
    Rules,
    RuleControls,
  },
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: state => state.approvals.rules,
    }),
  },
  methods: {
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
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead" slot-scope="{ name, members, approvalsRequired }">
      <tr class="d-none d-sm-table-row">
        <th v-if="settings.allowMultiRule">{{ name }}</th>
        <th class="w-50">{{ members }}</th>
        <th>{{ approvalsRequired }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tr" slot-scope="{ rule }">
      <td class="d-table-cell d-sm-none js-summary">{{ summaryText(rule) }}</td>
      <td v-if="settings.allowMultiRule" class="d-none d-sm-table-cell js-name">
        {{ rule.name }}
      </td>
      <td class="d-none d-sm-table-cell js-members">
        <user-avatar-list :items="rule.approvers" :img-size="24" />
      </td>
      <td class="d-none d-sm-table-cell js-approvals-required">
        <icon name="approval" class="align-top text-tertiary" />
        <span>{{ rule.approvalsRequired }}</span>
      </td>
      <td class="text-nowrap px-2 w-0 js-controls"><rule-controls :rule="rule" /></td>
    </template>
  </rules>
</template>

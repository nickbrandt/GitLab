<script>
import { n__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import RulesBase from './rules_base.vue';
import RuleControls from './rule_controls.vue';

export default {
  components: {
    Icon,
    UserAvatarList,
    RulesBase,
    RuleControls,
  },
  methods: {
    summaryText(rule) {
      return sprintf(
        n__(
          '%d approval required from %{name}',
          '%d approvals required from %{name}',
          rule.approvalsRequired,
        ),
        { name: rule.name },
      );
    },
  },
};
</script>

<template>
  <rules-base>
    <template slot="thead">
      <tr class="d-none d-sm-table-row">
        <th>{{ s__('ApprovalRule|Name') }}</th>
        <th class="w-50">{{ s__('ApprovalRule|Members') }}</th>
        <th>{{ s__('ApprovalRule|No. approvals required') }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tr" slot-scope="{ rule }">
      <td>
        <div class="d-none d-sm-block">{{ rule.name }}</div>
        <div class="d-block d-sm-none">{{ summaryText(rule) }}</div>
      </td>
      <td class="d-none d-sm-table-cell">
        <user-avatar-list :items="rule.approvers" :img-size="24" />
      </td>
      <td class="d-none d-sm-table-cell">
        <icon name="approval" class="align-top text-tertiary" />
        <span>{{ rule.approvalsRequired }}</span>
      </td>
      <td class="text-nowrap px-2 w-0"><rule-controls :rule="rule" /></td>
    </template>
  </rules-base>
</template>

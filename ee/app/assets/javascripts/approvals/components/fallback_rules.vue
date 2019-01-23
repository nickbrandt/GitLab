<script>
import { mapState } from 'vuex';
import { n__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from './rules.vue';
import RuleControls from './rule_controls.vue';

export default {
  components: {
    Icon,
    UserAvatarList,
    Rules,
    RuleControls,
  },
  computed: {
    ...mapState({
      approvalsRequired: state => state.approvals.fallbackApprovalsRequired,
    }),
    rules() {
      return [
        {
          isFallback: true,
          approvalsRequired: this.approvalsRequired,
        },
      ];
    },
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead">
      <tr class="d-none d-sm-table-row">
        <th class="w-75 pl-0">{{ s__('ApprovalRule|Members') }}</th>
        <th>{{ s__('ApprovalRule|No. approvals required') }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tr" slot-scope="{ rule }">
      <td data-name="members" class="pl-0">
        {{ s__('ApprovalRule|All members with Developer role or higher and code owners (if any)') }}
      </td>
      <td data-name="approvals_required">
        <slot name="approvals-required" :approvals-required="rule.approvalsRequired">
          <icon name="approval" class="align-top text-tertiary" />
          <span>{{ rule.approvalsRequired }}</span>
        </slot>
      </td>
      <td data-name="controls" class="text-nowrap px-2 w-0"><rule-controls :rule="rule" /></td>
    </template>
  </rules>
</template>

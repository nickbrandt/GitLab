<script>
import { mapState } from 'vuex';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import RulesBase from './rules_base.vue';
import RuleControls from './rule_controls.vue';

export default {
  components: {
    UserAvatarList,
    RulesBase,
    RuleControls,
  },
  computed: {
    ...mapState(['settings']),
  },
};
</script>

<template>
  <rules-base>
    <template slot="thead">
      <tr>
        <th>{{ s__('ApprovalRule|Name') }}</th>
        <th class="w-50 d-none d-sm-table-cell">{{ s__('ApprovalRule|Members') }}</th>
        <th>{{ s__('ApprovalRule|No. approvals required') }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tr" slot-scope="{ rule }">
      <td>{{ rule.name }}</td>
      <td class="d-none d-sm-table-cell">
        <user-avatar-list :items="rule.approvers" :img-size="24" />
      </td>
      <td>
        <input
          :value="rule.approvalsRequired"
          :name="`merge_request[approval_rules][${rule.id}][approvals_required]`"
          :disabled="!settings.canEdit"
          class="form-control mw-6em"
          type="number"
          min="0"
        />
      </td>
      <td class="text-nowrap px-2 w-0"><rule-controls v-if="settings.canEdit" :rule="rule" /></td>
    </template>
  </rules-base>
</template>

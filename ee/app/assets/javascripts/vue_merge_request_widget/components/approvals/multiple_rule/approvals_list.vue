<script>
import { sprintf, __ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import ApprovedIcon from './approved_icon.vue';

export default {
  components: {
    UserAvatarList,
    ApprovedIcon,
  },
  props: {
    approvalRules: {
      type: Array,
      required: true,
    },
  },
  methods: {
    pendingApprovalsText(rule) {
      if (!rule.approvals_required) {
        return __('Optional');
      }

      return sprintf(__('%{part} of %{total}'), {
        part: rule.approved_by.length,
        total: rule.approvals_required,
      });
    },
    isApproved(rule) {
      return rule.approvals_required > 0 && rule.approvals_required <= rule.approved_by.length;
    },
    summaryText(rule) {
      return rule.approvals_required === 0
        ? this.summaryOptionalText(rule)
        : this.summaryRequiredText(rule);
    },
    summaryRequiredText(rule) {
      return sprintf(__('%{count} of %{required} approvals from %{name}'), {
        count: rule.approved_by.length,
        required: rule.approvals_required,
        name: rule.name,
      });
    },
    summaryOptionalText(rule) {
      return sprintf(__('%{count} approvals from %{name}'), {
        count: rule.approved_by.length,
        name: rule.name,
      });
    },
  },
};
</script>

<template>
  <table class="table m-0">
    <thead class="thead-white text-nowrap">
      <tr class="d-none d-sm-table-row">
        <th class="w-0"></th>
        <th>{{ s__('MRApprovals|Approvers') }}</th>
        <th class="w-50"></th>
        <th>{{ s__('MRApprovals|Pending approvals') }}</th>
        <th>{{ s__('MRApprovals|Approved by') }}</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="rule in approvalRules" :key="rule.id">
        <td class="w-0"><approved-icon :is-approved="isApproved(rule)" /></td>
        <td :colspan="rule.fallback ? 2 : 1">
          <div class="d-none d-sm-block">{{ rule.name }}</div>
          <div class="d-block d-sm-none">
            <div class="d-flex flex-column">
              <div>{{ summaryText(rule) }}</div>
              <user-avatar-list class="mt-2" :items="rule.approvers" :img-size="24" />
              <div class="mt-2" v-if="rule.approved_by.length">
                <span>{{ s__('MRApprovals|Approved by') }}</span>
                <user-avatar-list
                  class="d-inline-block align-middle"
                  :items="rule.approved_by"
                  :img-size="24"
                />
              </div>
            </div>
          </div>
        </td>
        <td v-if="!rule.fallback" class="d-none d-sm-table-cell">
          <div><user-avatar-list :items="rule.approvers" :img-size="24" /></div>
        </td>
        <td class="w-0 d-none d-sm-table-cell text-nowrap">{{ pendingApprovalsText(rule) }}</td>
        <td class="d-none d-sm-table-cell">
          <user-avatar-list :items="rule.approved_by" :img-size="24" />
        </td>
      </tr>
    </tbody>
  </table>
</template>

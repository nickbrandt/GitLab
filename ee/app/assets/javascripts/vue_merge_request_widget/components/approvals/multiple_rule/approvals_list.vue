<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlLoadingIcon,
    UserAvatarList,
    Icon,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
    };
  },
  created() {
    const settingsAsync = this.service.fetchApprovalSettings();
    const approvalsAsync = this.service.fetchApprovals();
    Promise.all([approvalsAsync, settingsAsync])
      .then(([approvals, settings]) => ({
        ...approvals,
        approval_rules: settings.rules,
      }))
      .then(data => {
        this.mr.setApprovals(data);
        this.isLoading = false;
      })
      .catch(() => {});
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
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" />
    <table class="table m-0" v-else>
      <thead class="thead-white text-nowrap">
        <tr>
          <th></th>
          <th>{{ s__('MRApprovals|Approvers') }}</th>
          <th class="mw-50"></th>
          <th>{{ s__('MRApprovals|Pending approvals') }}</th>
          <th>{{ s__('MRApprovals|Approved by') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="rule in mr.approvalRules" :key="rule.id">
          <td>
            <template v-if="isApproved(rule)">
              <icon name="check-circle" class="text-success" />
            </template>
          </td>
          <td>{{ rule.name }}</td>
          <td><user-avatar-list :items="rule.approvers" :img-size="24" /></td>
          <td class="text-nowrap">{{ pendingApprovalsText(rule) }}</td>
          <td><user-avatar-list :items="rule.approved_by" :img-size="24" /></td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

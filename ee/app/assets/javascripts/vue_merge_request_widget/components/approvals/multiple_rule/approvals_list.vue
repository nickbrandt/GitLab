<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
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
          <th></th>
          <th>{{ s__('MRApprovals|Pending approvals') }}</th>
          <th>{{ s__('MRApprovals|Approved by') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for=""
      </tbody>
    </table>
  </div>
</template>

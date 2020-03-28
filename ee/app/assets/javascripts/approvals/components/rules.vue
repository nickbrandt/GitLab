<script>
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const HEADERS = {
  name: s__('ApprovalRule|Name'),
  members: s__('ApprovalRule|Approvers'),
  approvalsRequired: s__('ApprovalRule|No. approvals required'),
  branches: s__('Target branch'),
};

export default {
  mixins: [glFeatureFlagsMixin()],
  props: {
    rules: {
      type: Array,
      required: true,
    },
  },
  computed: {
    scopedApprovalRules() {
      return this.glFeatures.scopedApprovalRules;
    },
  },
  HEADERS,
};
</script>

<template>
  <table class="table m-0">
    <thead class="thead-white text-nowrap">
      <slot
        name="thead"
        v-bind="$options.HEADERS"
        :gl-features-scoped-approval-rules="scopedApprovalRules"
      ></slot>
    </thead>
    <tbody>
      <slot
        name="tbody"
        :rules="rules"
        :gl-features-scoped-approval-rules="scopedApprovalRules"
      ></slot>
    </tbody>
  </table>
</template>

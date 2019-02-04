<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import ApprovalsList from './approvals_list.vue';

export default {
  components: {
    Icon,
    GlButton,
    GlLoadingIcon,
    UserAvatarList,
    ApprovalsList,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    value: {
      type: Boolean,
      required: false,
      default: true,
    },
    isLoadingRules: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isCollapsed() {
      return !this.value;
    },
    hasApprovals() {
      return !!this.mr.approvals;
    },
    ariaLabel() {
      return this.isCollapsed ? __('Expand approvers') : __('Collapse approvers');
    },
    angleIcon() {
      return this.isCollapsed ? 'angle-right' : 'angle-down';
    },
    suggestedApprovers() {
      const items = this.mr.approvals.suggested_approvers;

      return items.slice(0, Math.min(5, items.length));
    },
  },
  methods: {
    toggle() {
      this.$emit('input', !this.value);
    },
  },
};
</script>

<template>
  <div v-if="this.hasApprovals">
    <div class="mr-widget-extension d-flex align-items-center pl-3">
      <div
        class="s32 svg-wrapper d-flex align-items-center justify-content-center append-right-default"
        role="button"
        :aria-label="ariaLabel"
        @click="toggle"
      >
        <gl-loading-icon v-if="!isCollapsed && isLoadingRules" />
        <icon v-else :name="angleIcon" :size="12" />
      </div>
      <template v-if="isCollapsed">
        <user-avatar-list :items="suggestedApprovers" :breakpoint="0" empty-text="" />
        <gl-button variant="link" @click="toggle">{{ __('View eligible approvers') }}</gl-button>
      </template>
      <template v-else>
        <gl-button variant="link" @click="toggle">{{ __('Collapse') }}</gl-button>
      </template>
    </div>
    <div class="border-top" v-if="!isCollapsed">
      <approvals-list :approval-rules="mr.approvalRules" v-if="mr.approvalRules.length" />
    </div>
  </div>
</template>

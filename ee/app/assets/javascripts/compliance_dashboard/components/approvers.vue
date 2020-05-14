<script>
import { sprintf, __ } from '~/locale';
import { GlAvatarLink, GlAvatar, GlTooltipDirective } from '@gitlab/ui';
import { PRESENTABLE_APPROVERS_LIMIT } from '../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatarLink,
    GlAvatar,
  },
  props: {
    approvers: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasApprovers() {
      return this.approvers.length > 0;
    },
    approversToPresent() {
      return this.approvers.slice(0, PRESENTABLE_APPROVERS_LIMIT);
    },
    amountOfApproversOverLimit() {
      return this.approvers.length - PRESENTABLE_APPROVERS_LIMIT;
    },
    isApproversOverLimit() {
      return this.amountOfApproversOverLimit > 0;
    },
    approversOverLimitString() {
      return sprintf(__('+%{approvers} more approvers'), {
        approvers: this.amountOfApproversOverLimit,
      });
    },
  },
  strings: {
    approvedBy: __('Approved by: '),
    noApprovers: __('No approvers'),
  },
};
</script>

<template>
  <li class="issuable-status d-flex approvers align-items-center">
    <span class="gl-text-gray-700">
      <template v-if="hasApprovers">
        {{ $options.strings.approvedBy }}
      </template>
      <template v-else>
        {{ $options.strings.noApprovers }}
      </template>
    </span>
    <gl-avatar-link
      v-for="approver in approversToPresent"
      :key="approver.id"
      :title="approver.name"
      :href="approver.web_url"
      :data-user-id="approver.id"
      :data-name="approver.name"
      class="d-flex align-items-center ml-2 author-link js-user-link "
    >
      <gl-avatar
        :src="approver.avatar_url"
        :entity-id="approver.id"
        :entity-name="approver.name"
        :size="16"
        class="mr-1"
      />
      <span>{{ approver.name }}</span>
    </gl-avatar-link>
    <span
      v-if="isApproversOverLimit"
      v-gl-tooltip.top="approversOverLimitString"
      class="avatar-counter ml-2"
      >+ {{ amountOfApproversOverLimit }}</span
    >
  </li>
</template>

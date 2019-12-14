<script>
import { GlPopover, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
    GlPopover,
    GlLink,
  },
  props: {
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <span class="mt-n1">{{ __('Any eligible user') }}</span>
    <span id="popovercontainer" class="ml-2 align-self-end">
      <icon
        id="pop-approver"
        name="question-o"
        :aria-label="__('help')"
        :size="14"
        class="author-link suggestion-help-hover"
      />
      <gl-popover
        target="pop-approver"
        container="popovercontainer"
        placement="top"
        triggers="focus"
      >
        <template #title>{{ __('Who can be an approver?') }}</template>
        <ul class="pl-3">
          <li>
            {{ __('Any member with Developer or higher permissions to the project.') }}
          </li>
          <li>{{ __('Code Owners to the merge request changes.') }}</li>
          <li>
            {{
              __("Users or groups set as approvers in the project's or merge request's settings.")
            }}
          </li>
        </ul>
        <gl-link :href="eligibleApproversDocsPath">{{ __('More information') }}</gl-link>
      </gl-popover>
    </span>
  </div>
</template>

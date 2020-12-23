<script>
import { GlButton, GlIcon, GlAvatar, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/groups/constants';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlIcon,
    GlAvatar,
    GlBadge,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  data() {
    return { namespaces: null, isLoading: false };
  },

  computed: {
    rowClass() {
      return {
        'has-description': this.group.description,
        'being-removed': this.isGroupPendingRemoval,
      };
    },
    isGroupPendingRemoval() {
      return this.group.marked_for_deletion_on;
    },
    isLinked() {
      // TODO: Pass groups that are linked from the backend and cross-check that list here
      return false;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.group.visibility];
    },
    visibilityTooltip() {
      return GROUP_VISIBILITY_TYPE[this.group.visibility];
    },
  },

  methods: {
    onClick() {
      this.isLoading = true;
      // TODO: Update with action to send axios request
    },
  },

  csrf,
};
</script>
<template>
  <li :class="rowClass" class="group-row gl-border-b-1 gl-border-b-solid gl-border-b-gray-200">
    <div class="group-row-contents gl-display-flex gl-align-items-center gl-py-3">
      <div class="folder-toggle-wrap gl-mr-3 gl-display-flex gl-align-items-center">
        <gl-icon name="folder-o" />
      </div>
      <span class="gl-display-none gl-flex-shrink-0 gl-display-sm-flex gl-mr-3">
        <gl-avatar :size="32" shape="rect" :entity-name="group.name" :src="group.avatarUrl" />
      </span>
      <div class="gl-min-w-0 gl-display-flex gl-flex-grow-1 gl-flex-shrink-1 gl-align-items-center">
        <div class="gl-min-w-0 gl-flex-grow-1 flex-shrink-1">
          <div class="title gl-display-flex gl-align-items-center gl-flex-wrap gl-mr-3">
            <span class="gl-mr-3 gl-text-gray-900! gl-font-weight-bold">{{ group.full_name }}</span>
            <gl-icon
              v-gl-tooltip.hover.bottom
              class="gl-mr-1 gl-inline-flex gl-text-gray-900"
              :name="visibilityIcon"
              :title="visibilityTooltip"
            />
            <gl-badge
              v-if="isGroupPendingRemoval"
              variant="warning"
              class="gl-display-none gl-display-sm-flex gl-mr-1"
              >{{ __('pending removal') }}</gl-badge
            >
            <span v-if="group.permission" class="user-access-role">
              {{ group.permission }}
            </span>
          </div>
          <div v-if="group.description">
            <p class="gl-mt-2! gl-mb-0 gl-text-gray-600" v-text="group.description"></p>
          </div>
        </div>

        <gl-button v-if="isLinked" disabled>{{ __('Linked') }}</gl-button>
        <gl-button
          v-else
          category="secondary"
          variant="success"
          :loading="isLoading"
          @click="onClick"
          >{{ __('Link') }}</gl-button
        >
      </div>
    </div>
  </li>
</template>

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
      return this.group.marked_for_deletion;
    },
    hasForkedProject() {
      return Boolean(this.group.forked_project_path);
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.group.visibility];
    },
    visibilityTooltip() {
      return GROUP_VISIBILITY_TYPE[this.group.visibility];
    },
    isSelectButtonDisabled() {
      return !this.group.can_create_project;
    },
  },

  methods: {
    onClick() {
      this.isLoading = true;
      this.$refs.form.submit();
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
              class="gl-mr-0 gl-inline-flex gl-text-gray-900"
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
        <div class="gl-display-flex gl-flex-shrink-0">
          <gl-button
            v-if="hasForkedProject"
            class="gl-h-7 gl-text-decoration-none!"
            :href="group.forked_project_path"
            >{{ __('Go to fork') }}</gl-button
          >
          <template v-else>
            <form ref="form" method="POST" :action="group.fork_path">
              <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
              <gl-button
                type="submit"
                class="gl-h-7"
                category="secondary"
                variant="success"
                :loading="isLoading"
                @click="onClick"
                >{{ __('Link') }}</gl-button
              >
            </form>
          </template>
        </div>
      </div>
    </div>
  </li>
</template>

<script>
import { GlDeprecatedButton, GlButton, GlButtonGroup } from '@gitlab/ui';
import allDesignsMixin from '../../mixins/all_designs';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import DeleteButton from '../delete_button.vue';
import permissionsQuery from '../../graphql/queries/design_permissions.query.graphql';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    Icon,
    DeleteButton,
    GlDeprecatedButton,
    GlButton,
    GlButtonGroup,
  },
  mixins: [timeagoMixin, allDesignsMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
    isDeleting: {
      type: Boolean,
      required: true,
    },
    filename: {
      type: String,
      required: false,
      default: '',
    },
    updatedAt: {
      type: String,
      required: false,
      default: null,
    },
    updatedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    image: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      permissions: {
        createDesign: false,
      },
    };
  },
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
  },
  apollo: {
    permissions: {
      query: permissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: data => data.project.issue.userPermissions,
    },
  },
  computed: {
    updatedText() {
      return sprintf(__('Updated %{updated_at} by %{updated_by}'), {
        updated_at: this.timeFormatted(this.updatedAt),
        updated_by: this.updatedBy.name,
      });
    },
    canDeleteDesign() {
      return this.permissions.createDesign;
    },
    designsCount() {
      return this.designs.length;
    },
    currentIndex() {
      return this.designs.findIndex(design => design.filename === this.id);
    },
    paginationText() {
      return sprintf(__('%{current_design} of %{designs_count}'), {
        current_design: this.currentIndex + 1,
        designs_count: this.designsCount,
      });
    },
    previousDesign() {
      if (this.currentIndex === 0) return null;

      return this.designs[this.currentIndex - 1].filename;
    },
    nextDesign() {
      if (this.currentIndex + 1 === this.designsCount) return null;

      return this.designs[this.currentIndex + 1].filename;
    },
  },
  DESIGNS_ROUTE_NAME,
};
</script>

<template>
  <header class="d-flex p-2 bg-white align-items-center js-design-header">
    <router-link
      :to="{
        name: $options.DESIGNS_ROUTE_NAME,
        query: $route.query,
      }"
      :aria-label="s__('DesignManagement|Go back to designs')"
      data-testid="close-design"
      class="mr-3 text-plain d-flex justify-content-center align-items-center"
    >
      <icon :size="18" name="close" />
    </router-link>
    <div class="overflow-hidden d-flex align-items-center gl-justify-content-space-between w-100">
      <div class="d-flex align-items-center">
        <h2 class="m-0 str-truncated-100 gl-font-base">{{ filename }}</h2>
        <small v-if="updatedAt" class="text-secondary">{{ updatedText }}</small>
      </div>
      <div class="design-actions d-flex align-items-center">
        <span class="gl-white-space-nowrap">{{ paginationText }}</span>
        <gl-button-group class="gl-ml-3 gl-mr-3">
          <gl-button
            :disabled="!previousDesign"
            :href="previousDesign"
            :title="s__('DesignManagement|Go to previous design')"
            icon="angle-left"
          />
          <gl-button
            :disabled="!nextDesign"
            :href="nextDesign"
            :title="s__('DesignManagement|Go to next design')"
            icon="angle-right"
          />
        </gl-button-group>
        <gl-deprecated-button :href="image" class="mr-2">
          <icon :size="18" name="download" />
        </gl-deprecated-button>
        <delete-button
          v-if="isLatestVersion && canDeleteDesign"
          :is-deleting="isDeleting"
          button-variant="danger"
          @deleteSelectedDesigns="$emit('delete')"
        >
          <icon :size="18" name="remove" />
        </delete-button>
      </div>
    </div>
  </header>
</template>

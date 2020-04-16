<script>
import PackageTags from '../../shared/components/package_tags.vue';
import PublishMethod from './publish_method.vue';
import { GlButton, GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { getPackageType } from '../../shared/utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { mapState } from 'vuex';

export default {
  name: 'PackagesListRow',
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    PackageTags,
    PublishMethod,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      isGroupPage: state => state.config.isGroupPage,
    }),
    packageType() {
      return getPackageType(this.packageEntity.package_type);
    },
    hasPipeline() {
      return Boolean(this.packageEntity.pipeline);
    },
    hasProjectLink() {
      return Boolean(this.packageEntity.project_path);
    },
    deleteAvailable() {
      return !this.isGroupPage;
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row" data-qa-selector="packages-row">
    <div class="table-section section-50 d-flex flex-md-column justify-content-between flex-wrap">
      <div class="d-flex align-items-center mr-2">
        <gl-link :href="packageEntity._links.web_path" class="text-dark font-weight-bold mb-md-1">
          {{ packageEntity.name }}
        </gl-link>

        <package-tags
          v-if="packageEntity.tags && packageEntity.tags.length"
          class="prepend-left-8"
          :tags="packageEntity.tags"
          hide-label
          :tag-display-limit="1"
        />
      </div>

      <div class="d-flex text-secondary text-truncate mt-md-2">
        <span>{{ packageEntity.version }}</span>

        <div v-if="hasPipeline" class="d-none d-md-inline-block ml-1">
          <gl-sprintf :message="s__('PackageRegistry|published by %{author}')">
            <template #author>{{ packageEntity.pipeline.user.name }}</template>
          </gl-sprintf>
        </div>

        <div v-if="hasProjectLink" class="d-flex align-items-center">
          <gl-icon name="review-list" class="text-secondary ml-2 mr-1" />

          <gl-link
            ref="packages-row-project"
            :href="`/${packageEntity.project_path}`"
            class="text-secondary"
            >{{ packageEntity.projectPathName }}</gl-link
          >
        </div>

        <div class="d-flex align-items-center">
          <gl-icon name="package" class="text-secondary ml-2 mr-1" />
          <span ref="package-type">{{ packageType }}</span>
        </div>
      </div>
    </div>

    <div
      class="table-section d-flex flex-md-column justify-content-between align-items-md-end"
      :class="isGroupPage ? 'section-50' : 'section-40'"
    >
      <publish-method :package-entity="packageEntity" />

      <div class="text-secondary order-0 order-md-1 mt-md-2">
        <gl-sprintf :message="__('Created %{timestamp}')">
          <template #timestamp>
            <span v-gl-tooltip :title="tooltipTitle(packageEntity.created_at)">
              {{ timeFormatted(packageEntity.created_at) }}
            </span>
          </template>
        </gl-sprintf>
      </div>
    </div>

    <div v-if="deleteAvailable" class="table-section section-10 d-flex justify-content-end">
      <gl-button
        ref="action-delete"
        icon="remove"
        category="primary"
        variant="danger"
        :title="s__('PackageRegistry|Remove package')"
        :aria-label="s__('PackageRegistry|Remove package')"
        :disabled="!packageEntity._links.delete_api_path"
        @click="$emit('packageToDelete', packageEntity)"
      />
    </div>
  </div>
</template>

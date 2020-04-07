<script>
import PackageTags from '../../shared/components/package_tags.vue';
import PublishMethod from './publish_method.vue';
import { GlDeprecatedButton, GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getPackageType } from '../../shared/utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { mapState } from 'vuex';

export default {
  name: 'PackagesListRow',
  components: {
    GlDeprecatedButton,
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
    createdBy() {
      if (this.packageEntity.pipeline) {
        return s__('PackageRegistry|%{version} published by %{author}');
      }

      return '%{version}';
    },
    packageType() {
      return getPackageType(this.packageEntity.package_type);
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
        <gl-link :href="packageEntity._links.web_path" class="text-dark font-weight-bold mb-md-1">{{
          packageEntity.name
        }}</gl-link>
        <package-tags
          v-if="packageEntity.tags && packageEntity.tags.length"
          class="prepend-left-8"
          :tags="packageEntity.tags"
          hide-label
          :tag-display-limit="1"
        />
      </div>

      <div class="d-flex text-secondary text-truncate mt-md-2">
        <gl-sprintf :message="createdBy">
          <template #version>
            <gl-icon name="eye" class="text-secondary mr-1" />
            {{ packageEntity.version }}
          </template>

          <template #author>{{ packageEntity.pipeline.user.name }}</template>
        </gl-sprintf>

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
      class="table-section section-40 d-flex flex-md-column justify-content-between align-items-md-end"
      :class="{ 'section-50': isGroupPage }"
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
      <gl-deprecated-button
        ref="action-delete"
        variant="danger"
        :title="s__('PackageRegistry|Remove package')"
        :aria-label="s__('PackageRegistry|Remove package')"
        :disabled="!packageEntity._links.delete_api_path"
        @click="$emit('packageToDelete', packageEntity)"
      >
        <gl-icon name="remove" />
      </gl-deprecated-button>
    </div>
  </div>
</template>

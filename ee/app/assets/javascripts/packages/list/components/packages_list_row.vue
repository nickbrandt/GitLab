<script>
import PackageTags from '../../shared/components/package_tags.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { GlButton, GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getPackageType } from '../../shared/utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'PackagesListRow',
  components: {
    ClipboardButton,
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    PackageTags,
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
    ...mapGetters(['getCommitLink']),
    ...mapState({
      isGroupPage: state => state.config.isGroupPage,
    }),
    author() {
      return this.packageEntity.pipeline?.user.name;
    },
    hasPipeline() {
      return Boolean(this.packageEntity.pipeline);
    },
    createdBy() {
      if (this.hasPipeline) {
        return s__('PackageRegistry|%{version} published by %{author}');
      }

      return '%{version}';
    },
    packageType() {
      return getPackageType(this.packageEntity.package_type);
    },
    packageShaShort() {
      return this.packageEntity.pipeline.sha.substring(0, 8);
    },
    linkToCommit() {
      return this.getCommitLink(this.packageEntity);
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

      <div class="d-flex text-secondary text-truncate">
        <gl-sprintf :message="createdBy">
          <template #version>
            {{ packageEntity.version }}
          </template>

          <template #author>{{ packageEntity.pipeline.user.name }}</template>
        </gl-sprintf>

        <gl-link
          v-if="hasProjectLink"
          ref="packages-row-project"
          :href="`/${packageEntity.project_path}`"
          class="text-secondary ml-2"
          >{{ packageEntity.projectPathName }}</gl-link
        >

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
      <div
        v-if="hasPipeline"
        class="d-flex align-items-center text-secondary order-1 order-md-0 mb-md-1"
      >
        <gl-icon name="git-merge" class="mr-1" />
        <strong ref="pipeline-ref" class="mr-1 text-dark">{{ packageEntity.pipeline.ref }}</strong>

        <gl-icon name="commit" class="mr-1" />
        <gl-link ref="pipeline-sha" :href="linkToCommit" class="mr-1">{{
          packageShaShort
        }}</gl-link>

        <clipboard-button
          :text="packageEntity.pipeline.sha"
          :title="__('Copy commit SHA')"
          css-class="border-0 text-secondary py-0 px-1"
        />
      </div>

      <div class="text-secondary order-0 order-md-1">
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
        variant="danger"
        :title="s__('PackageRegistry|Remove package')"
        :aria-label="s__('PackageRegistry|Remove package')"
        :disabled="!packageEntity._links.delete_api_path"
        @click="$emit('packageToDelete', packageEntity)"
      >
        <gl-icon name="remove" />
      </gl-button>
    </div>
  </div>
</template>

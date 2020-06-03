<script>
import { mapState, mapGetters } from 'vuex';
import { GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import PackageTags from '../../shared/components/package_tags.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  name: 'PackageTitle',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    PackageTags,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  computed: {
    ...mapState(['packageEntity', 'packageFiles']),
    ...mapGetters(['packageTypeDisplay', 'packagePipeline']),
    hasTagsToDisplay() {
      return Boolean(this.packageEntity.tags && this.packageEntity.tags.length);
    },
    totalSize() {
      return numberToHumanSize(this.packageFiles.reduce((acc, p) => acc + p.size, 0));
    },
  },
};
</script>

<template>
  <div class="flex-column">
    <h1 class="gl-font-size-20-deprecated-no-really-do-not-use-me gl-mt-3 append-bottom-4">
      {{ packageEntity.name }}
    </h1>

    <div class="gl-display-flex gl-align-items-center text-secondary">
      <gl-icon name="eye" class="gl-mr-3" />
      <gl-sprintf message="v%{version} published %{timeAgo}">
        <template #version>
          {{ packageEntity.version }}
        </template>

        <template #timeAgo>
          <span v-gl-tooltip :title="tooltipTitle(packageEntity.created_at)">
            &nbsp;{{ timeFormatted(packageEntity.created_at) }}
          </span>
        </template>
      </gl-sprintf>
    </div>

    <div class="gl-display-flex flex-wrap gl-align-items-center append-bottom-8">
      <div v-if="packageTypeDisplay" class="gl-display-flex align-items-center gl-mr-5">
        <gl-icon name="package" class="text-secondary gl-mr-3" />
        <span ref="package-type" class="font-weight-bold">{{ packageTypeDisplay }}</span>
      </div>

      <div v-if="hasTagsToDisplay" class="gl-display-flex gl-align-items-center gl-mr-5">
        <package-tags :tag-display-limit="1" :tags="packageEntity.tags" />
      </div>

      <div v-if="packagePipeline" class="gl-display-flex gl-align-items-center gl-mr-5">
        <gl-icon name="review-list" class="text-secondary gl-mr-3" />
        <gl-link
          ref="pipeline-project"
          :href="packagePipeline.project.web_url"
          class="font-weight-bold text-truncate"
        >
          {{ packagePipeline.project.name }}
        </gl-link>
      </div>

      <div
        v-if="packagePipeline"
        ref="package-ref"
        class="gl-display-flex gl-align-items-center gl-mr-5"
      >
        <gl-icon name="branch" class="text-secondary gl-mr-3" />
        <span
          v-gl-tooltip
          class="font-weight-bold text-truncate mw-xs"
          :title="packagePipeline.ref"
          >{{ packagePipeline.ref }}</span
        >
      </div>

      <div class="gl-display-flex gl-align-items-center gl-mr-5">
        <gl-icon name="disk" class="text-secondary gl-mr-3" />
        <span ref="package-size" class="font-weight-bold">{{ totalSize }}</span>
      </div>
    </div>
  </div>
</template>

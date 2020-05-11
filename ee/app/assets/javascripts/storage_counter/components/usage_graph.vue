<script>
import { s__ } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';

export default {
  props: {
    rootStorageStatistics: {
      required: true,
      type: Object,
    },
  },
  computed: {
    storageTypes() {
      const {
        buildArtifactsSize,
        lfsObjectsSize,
        packagesSize,
        repositorySize,
        storageSize,
        wikiSize,
      } = this.rootStorageStatistics;

      if (storageSize === 0) {
        return null;
      }

      return [
        {
          name: s__('UsageQuota|Repositories'),
          percentage: this.sizePercentage(repositorySize),
          class: 'gl-bg-data-viz-blue-500',
          size: repositorySize,
        },
        {
          name: s__('UsageQuota|LFS Objects'),
          percentage: this.sizePercentage(lfsObjectsSize),
          class: 'gl-bg-data-viz-orange-600',
          size: lfsObjectsSize,
        },
        {
          name: s__('UsageQuota|Packages'),
          percentage: this.sizePercentage(packagesSize),
          class: 'gl-bg-data-viz-aqua-500',
          size: packagesSize,
        },
        {
          name: s__('UsageQuota|Build Artifacts'),
          percentage: this.sizePercentage(buildArtifactsSize),
          class: 'gl-bg-data-viz-green-600',
          size: buildArtifactsSize,
        },
        {
          name: s__('UsageQuota|Wikis'),
          percentage: this.sizePercentage(wikiSize),
          class: 'gl-bg-data-viz-magenta-500',
          size: wikiSize,
        },
      ]
        .filter(data => data.size !== 0)
        .sort((a, b) => b.size - a.size);
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    sizePercentage(size) {
      const { storageSize } = this.rootStorageStatistics;

      return (size / storageSize) * 100;
    },
  },
};
</script>
<template>
  <div v-if="storageTypes" class="gl-display-flex gl-flex-direction-column w-100">
    <div class="gl-h-6 my-3">
      <div
        v-for="storageType in storageTypes"
        :key="storageType.name"
        class="storage-type-usage gl-h-full gl-display-inline-block"
        :class="storageType.class"
        :style="{ width: `${storageType.percentage}%` }"
      ></div>
    </div>
    <div class="row py-0">
      <div
        v-for="storageType in storageTypes"
        :key="storageType.name"
        class="col-md-auto gl-display-flex gl-align-items-center"
        data-testid="storage-type"
      >
        <div class="gl-h-2 gl-w-5 gl-mr-2 gl-display-inline-block" :class="storageType.class"></div>
        <span class="gl-mr-2 gl-font-weight-bold gl-font-sm">
          {{ storageType.name }}
        </span>
        <span class="gl-text-gray-700 gl-font-sm">
          {{ formatSize(storageType.size) }}
        </span>
      </div>
    </div>
  </div>
</template>

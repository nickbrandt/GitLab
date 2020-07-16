<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import Project from './project.vue';
import UsageGraph from './usage_graph.vue';
import query from '../queries/storage.query.graphql';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Project,
    GlLink,
    GlSprintf,
    Icon,
    UsageGraph,
  },
  props: {
    namespacePath: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    purchaseStorageUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    namespace: {
      query,
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
      /**
       * `rootStorageStatistics` will be sent as null until an
       * event happens to trigger the storage count.
       * For that reason we have to verify if `storageSize` is sent or
       * if we should render N/A
       */
      update: data => ({
        projects: data.namespace.projects.edges.map(({ node }) => node),
        totalUsage:
          data.namespace.rootStorageStatistics && data.namespace.rootStorageStatistics.storageSize
            ? numberToHumanSize(data.namespace.rootStorageStatistics.storageSize)
            : 'N/A',
        rootStorageStatistics: data.namespace.rootStorageStatistics,
        limit: data.namespace.storageSizeLimit,
      }),
    },
  },
  data() {
    return {
      namespace: {},
    };
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
  },
};
</script>
<template>
  <div>
    <div class="pipeline-quota container-fluid py-4 px-2 m-0">
      <div class="row py-0 d-flex align-items-center">
        <div class="col-sm-8">
          <gl-sprintf :message="s__('UsageQuota|You used: %{usage} %{limit}')">
            <template #usage>
              <span class="gl-font-weight-bold" data-testid="total-usage">
                {{ namespace.totalUsage }}
              </span>
            </template>
            <template #limit>
              <gl-sprintf
                v-if="namespace.limit"
                :message="s__('UsageQuota|out of %{formattedLimit} of your namespace storage')"
              >
                <template #formattedLimit>
                  <span class="gl-font-weight-bold">{{ formatSize(namespace.limit) }}</span>
                </template>
              </gl-sprintf>
            </template>
          </gl-sprintf>
          <gl-link
            :href="helpPagePath"
            target="_blank"
            :aria-label="s__('UsageQuota|Usage quotas help link')"
          >
            <icon name="question" :size="12" />
          </gl-link>
        </div>
        <div v-if="purchaseStorageUrl" class="col-sm-4 text-right">
          <gl-link
            :href="purchaseStorageUrl"
            class="btn btn-success"
            target="_blank"
            data-testid="purchase-storage-link"
            >{{ s__('UsageQuota|Purchase more storage') }}</gl-link
          >
        </div>
      </div>
      <div class="row py-0">
        <div class="col-sm-12">
          <usage-graph
            v-if="namespace.rootStorageStatistics"
            :root-storage-statistics="namespace.rootStorageStatistics"
            :limit="namespace.limit"
          />
        </div>
      </div>
    </div>
    <div class="ci-table" role="grid">
      <div
        class="gl-responsive-table-row table-row-header bg-gray-light pl-2 border-top mt-3 lh-100"
        role="row"
      >
        <div class="table-section section-70 font-weight-bold" role="columnheader">
          {{ __('Project') }}
        </div>
        <div class="table-section section-30 font-weight-bold" role="columnheader">
          {{ __('Usage') }}
        </div>
      </div>

      <project v-for="project in namespace.projects" :key="project.id" :project="project" />
    </div>
  </div>
</template>

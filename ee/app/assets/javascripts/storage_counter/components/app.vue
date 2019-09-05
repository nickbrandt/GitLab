<script>
import { GlLink } from '@gitlab/ui';
import Project from './project.vue';
import query from '../queries/storage.graphql';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Project,
    GlLink,
    Icon,
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
      }),
    },
  },
  data() {
    return {
      namespace: {},
    };
  },
};
</script>
<template>
  <div>
    <div class="pipeline-quota container-fluid">
      <div class="row">
        <div class="col-sm-6">
          <strong>{{ s__('UsageQuota|Usage since') }}</strong>
          <div>
            <span class="js-total-usage">
              {{ namespace.totalUsage }}
              <gl-link
                :href="helpPagePath"
                target="_blank"
                :aria-label="__('Usage quotas help link')"
              >
                <icon name="question" :size="12" />
              </gl-link>
            </span>
          </div>
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

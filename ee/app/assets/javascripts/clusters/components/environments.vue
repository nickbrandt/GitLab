<script>
import { GlTable, GlLink, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlEmptyState,
    GlTable,
    GlLink,
    Icon,
    TimeAgo,
    GlLoadingIcon,
    deploymentInstance: () => import('ee_component/vue_shared/components/deployment_instance.vue'),
  },
  props: {
    isFetching: {
      type: Boolean,
      required: true,
    },
    environments: {
      type: Array,
      required: true,
    },
    environmentsHelpPath: {
      type: String,
      required: true,
    },
    clustersHelpPath: {
      type: String,
      required: true,
    },
    deployBoardsHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    isEmpty() {
      return !this.isFetching && this.environments.length === 0;
    },
    tableEmptyStateText() {
      const text = __(
        'Ensure your %{linkStart}environment is part of the deploy stage%{linkEnd} of your CI pipeline to track deployments to your cluster.',
      );
      const linkStart = `<a href="${this.environmentsHelpPath}">`;
      const linkEnd = `</a>`;

      return sprintf(text, { linkStart, linkEnd }, false);
    },
    deploymentsEmptyStateText() {
      const text = __(
        'Deploy progress not found. To see pods, ensure your environment matches %{linkStart}deploy board criteria%{linkEnd}.',
      );
      const linkStart = `<a href="${this.deployBoardsHelpPath}">`;
      const linkEnd = `</a>`;

      return sprintf(text, { linkStart, linkEnd }, false);
    },
    podsInUseCount() {
      let podsInUse = 0;

      this.environments.forEach(environment => {
        if (this.hasInstances(environment.rolloutStatus)) {
          podsInUse += environment.rolloutStatus.instances.length;
        }
      });

      return podsInUse;
    },
  },
  created() {
    this.$options.fields = [
      { key: 'project', label: __('Project'), class: 'pl-0 pr-5 text-nowrap' },
      { key: 'name', label: __('Environment'), class: 'pl-0 pr-5' },
      { key: 'lastDeployment', label: __('Job'), class: 'pl-0 pr-5 text-nowrap' },
      { key: 'rolloutStatus', label: __('Pods in use'), class: 'pl-0 pr-5' },
      {
        key: 'updatedAt',
        label: __('Last updated'),
        class: 'pl-0 pr-0 text-md-right text-nowrap',
      },
    ];
  },
  methods: {
    hasInstances: rolloutStatus => rolloutStatus.instances && rolloutStatus.instances.length,
    isLoadingRollout: rolloutStatus => rolloutStatus.status === 'loading',
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="isEmpty"
      :title="__('No deployments found')"
      :primary-button-link="clustersHelpPath"
      :primary-button-text="__('Learn more about deploying to a cluster')"
    >
      <div slot="description" v-html="tableEmptyStateText"></div>
    </gl-empty-state>

    <gl-table
      v-if="!isFetching && !isEmpty"
      :fields="$options.fields"
      :items="environments"
      head-variant="white"
    >
      <!-- column: Project -->
      <template slot="project" slot-scope="data">
        <a :href="`/${data.value.path_with_namespace}`">{{ data.value.name }}</a>
      </template>

      <!-- column: Name -->
      <template slot="name" slot-scope="row">
        <a :href="`${row.item.environmentPath}`">{{ row.item.name }}</a>
      </template>

      <!-- column: Job -->
      <template slot="lastDeployment" slot-scope="data">
        {{ __('deploy') }} #{{ data.value.id }}
      </template>

      <!-- column: Pods in use -->
      <template slot="HEAD_rolloutStatus" slot-scope="data">
        {{ data.label }} <span class="badge badge-pill pods-badge bold">{{ podsInUseCount }}</span>
      </template>

      <template slot="rolloutStatus" slot-scope="row">
        <!-- Loading Rollout -->
        <gl-loading-icon
          v-if="isLoadingRollout(row.item.rolloutStatus)"
          class="d-inline-flex mt-1"
        />

        <!-- Rollout Instances -->
        <div v-else-if="hasInstances(row.item.rolloutStatus)" class="d-flex flex-wrap flex-row">
          <template v-for="(instance, i) in row.item.rolloutStatus.instances">
            <deployment-instance
              :key="i"
              :status="instance.status"
              :tooltip-text="instance.tooltip"
              :pod-name="instance.pod_name"
              :stable="instance.stable"
              :project-path="`/${row.item.project.path_with_namespace}`"
              :environment-name="row.item.name"
            />
          </template>
        </div>

        <!-- Empty state -->
        <div v-else class="deployments-empty d-flex">
          <icon
            name="warning"
            :size="18"
            class="cluster-deployments-warning mr-2 align-self-center flex-shrink-0"
          />
          <span v-html="deploymentsEmptyStateText"></span>
        </div>
      </template>

      <!-- column: Last updated -->
      <template slot="updatedAt" slot-scope="data">
        <time-ago :time="data.value" />
      </template>
    </gl-table>

    <gl-loading-icon v-if="isFetching" :size="2" class="mt-3" />
  </div>
</template>

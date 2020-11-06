<script>
import { GlAlert, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import AgentEmptyState from './agent_empty_state.vue';
import AgentTable from './agent_table.vue';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';

export default {
  apollo: {
    agents: {
      query: getAgentsQuery,
      variables() {
        return {
          defaultBranchName: this.defaultBranchName,
          projectPath: this.projectPath,
        };
      },
      update: data => data
    },
  },
  components: {
    AgentEmptyState,
    AgentTable,
    GlAlert,
    GlKeysetPagination,
    GlLoadingIcon,
  },
  props: {
    emptyStateImage: {
      required: true,
      type: String,
    },
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
    projectPath: {
      required: true,
      type: String,
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.agents.loading;
    },
    agentList() {
      let list = this.agents?.project?.clusterAgents?.nodes;
      const configFolders = this.agents?.project?.repository?.tree?.trees?.nodes;

      if (list && configFolders) {
        list = list.map(agent => {
          const configFolder = configFolders.find(({ name }) => name === agent.name);
          return { ...agent, configFolder };
        });
      }

      return list;
    },
    agentPageInfo() {
      return this.agents?.project?.clusterAgents?.pageInfo;
    }
  },
  methods: {
    updatePagination(item) {
      console.log(item)
    }
  }
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-3" />

  <section v-else-if="agentList" class="gl-mt-3">
    <div v-if="agentList.length">
      <AgentTable :agents="agentList" />

      <gl-keyset-pagination
        v-bind="agentPageInfo"
        @prev="updatePagination"
        @next="updatePagination"
      />
    </div>

    <AgentEmptyState v-else :image="emptyStateImage" />
  </section>

  <gl-alert v-else variant="danger" :dismissible="false">
    {{ s__('ClusterAgents|An error occurred while loading your GitLab Agents') }}
  </gl-alert>
</template>

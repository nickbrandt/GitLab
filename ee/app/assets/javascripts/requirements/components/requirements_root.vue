<script>
import * as Sentry from '@sentry/browser';
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import createFlash from '~/flash';

import RequirementsEmptyState from './requirements_empty_state.vue';
import RequirementItem from './requirement_item.vue';
import projectRequirements from '../queries/projectRequirements.query.graphql';

import { FilterState } from '../constants';

export default {
  components: {
    GlLoadingIcon,
    RequirementsEmptyState,
    RequirementItem,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    filterBy: {
      type: String,
      required: true,
    },
    showCreateRequirement: {
      type: Boolean,
      required: true,
    },
    emptyStatePath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    requirements: {
      query: projectRequirements,
      variables() {
        const queryVariables = {
          projectPath: this.projectPath,
        };

        if (this.filterBy !== FilterState.all) {
          queryVariables.state = this.filterBy;
        }

        return queryVariables;
      },
      update: data => data.project?.requirements?.nodes || [],
      error: e => {
        createFlash(__('Something went wrong while fetching requirements list.'));
        Sentry.captureException(e);
      },
    },
  },
  data() {
    return {
      requirements: [],
    };
  },
  computed: {
    requirementsListLoading() {
      return this.$apollo.queries.requirements.loading;
    },
    requirementsListEmpty() {
      return !this.$apollo.queries.requirements.loading && !this.requirements.length;
    },
  },
};
</script>

<template>
  <div class="requirements-list-container">
    <requirements-empty-state
      v-if="requirementsListEmpty"
      :filter-by="filterBy"
      :empty-state-path="emptyStatePath"
    />
    <gl-loading-icon v-if="requirementsListLoading" class="mt-3" size="md" />
    <ul v-else class="content-list issuable-list issues-list requirements-list">
      <requirement-item
        v-for="requirement in requirements"
        :key="requirement.iid"
        :requirement="requirement"
      />
    </ul>
  </div>
</template>

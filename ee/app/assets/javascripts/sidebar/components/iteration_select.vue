<script>
import {
  GlButton,
  GlLink,
  GlNewDropdown,
  GlNewDropdownItem,
  GlSearchBoxByType,
  GlNewDropdownHeader,
  GlNewDropdownDivider,
} from '@gitlab/ui';
import debounce from 'lodash/debounce';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import groupIterationssQuery from '../queries/group_iterations.query.graphql';
import currentIterationQuery from '../queries/issue_iteration.query.graphql';
import setIssueIterationMutation from '../queries/set_iteration_on_issue.mutation.graphql';
import createFlash from '~/flash';

export default {
  components: {
    GlButton,
    GlLink,
    GlNewDropdown,
    GlNewDropdownItem,
    GlSearchBoxByType,
    GlNewDropdownHeader,
    GlNewDropdownDivider,
    Icon,
  },
  props: {
    canEdit: {
      required: true,
      type: Boolean,
    },
    groupPath: {
      required: true,
      type: String,
    },
    projectPath: {
      required: true,
      type: String,
    },
    issueIid: {
      required: true,
      type: String,
    },
  },
  apollo: {
    currentIteration: {
      query: currentIterationQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update(data) {
        if (!data) {
          return null;
        }

        if (data.project.issues.nodes[0].iteration === null) {
          return null;
        }

        return data.project.issues.nodes[0].iteration.id;
      },
    },
    iterations: {
      query: groupIterationssQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        // if data.group.sprints.nodes.length == 0
        return data.group.iterations.nodes; // map the ids and convert?
      },
    },
  },
  data() {
    return {
      searchTerm: '',
      editing: false,
    };
  },
  computed: {
    selectedIteration() {
      if (this.iterations) {
        return this.iteration;
      }
    },
    iteration() {
      const iteration = this.iterations.find(({ id }) => id === this.currentIteration);

      if (iteration) {
        return iteration.title;
      }
    },
  },
  mounted() {
    document.addEventListener('click', this.handleOffClick);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleOffClick);
  },
  methods: {
    toggleDropdown(e) {
      // NOTE: need this here to not trigger milestone dropdown.
      e.stopPropagation();

      this.editing = !this.editing;
    },
    search: debounce(function(e) {
      this.searchTerm = e;

      this.$apollo.queries.iterations.refetch({
        title: `"${e}"`,
        fullPath: this.groupPath,
      });
    }, 250),
    setIteration(iterationId) {
      this.editing = false;

      this.$apollo
        .mutate({
          mutation: setIssueIterationMutation,
          variables: {
            projectPath: this.projectPath,
            iterationId,
            iid: this.issueIid,
          },
        })
        .then(({ data }) => {
          const { iteration } = data.issueSetIteration.issue;

          if (iteration === null) {
            this.currentIteration = null;
          } else {
            this.currentIteration = iteration.id;
          }
        })
        .catch(() => {
          createFlash(__('Failed to set iteration on this issue. Please try again.'));
        });
    },
    handleOffClick(event) {
      if (!this.editing) return;

      if (!this.$refs.dropdown.$el.contains(event.target)) {
        this.toggleDropdown(event);
      }
    },
    isIterationChecked(iterationId = null) {
      return iterationId === this.currentIteration;
    },
  },
};
</script>

<template>
  <div class="mt-3">
    <div class="sidebar-collapsed-icon" b-gl-tooltip>
      <icon :size="16" :aria-label="__('Iteration')" name="history" />
      <span class="bold collapse-truncated-title">{{ selectedIteration }}</span>
    </div>
    <div class="title hide-collapsed">
      {{ __('Iteration') }}
      <gl-button
        v-if="canEdit"
        class="js-sidebar-dropdown-toggle edit-link float-right"
        data-track-label="right_sidebar"
        data-track-property="iteration"
        data-track-event="click_edit_button"
        @click="toggleDropdown"
      >{{ __('Edit') }}</gl-button>
    </div>
    <div class="value hide-collapsed">
      <gl-link v-if="!editing" class="bold" href>{{ selectedIteration }}</gl-link>
      <span v-if="!editing && !currentIteration" class="no-value">{{ __('None') }}</span>
    </div>
    <gl-new-dropdown
      v-show="editing"
      ref="dropdown"
      data-toggle="dropdown"
      :text="selectedIteration"
      class="dropdown w-100"
      :class="editing && 'show'"
    >
      <gl-new-dropdown-header>{{ __('Assign Iteration') }}</gl-new-dropdown-header>
      <gl-new-dropdown-divider />
      <gl-search-box-by-type :value="searchTerm" @input="search" />
      <gl-new-dropdown-item
        :is-checked="isIterationChecked()"
        :active="true"
        :is-check-item="true"
        @click="setIteration(null)"
      >{{ __('None') }}</gl-new-dropdown-item>
      <gl-new-dropdown-item
        v-for="iterationItem in iterations"
        :key="iterationItem.id"
        :is-check-item="true"
        :is-checked="isIterationChecked(iterationItem.id)"
        @click="setIteration(iterationItem.id)"
      >{{ iterationItem.title }}</gl-new-dropdown-item>
    </gl-new-dropdown>
  </div>
</template>

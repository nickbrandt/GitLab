<script>
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import Assignee from './assignee.vue';
import IssueReference from './issue_reference.vue';

export default {
  name: 'JiraIssuesSidebar',
  components: {
    Assignee,
    IssueReference,
    LabelsSelect,
  },
  props: {
    sidebarExpanded: {
      type: Boolean,
      required: true,
    },
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    assignee() {
      // Jira issues have at most 1 assignee
      return (this.issue?.assignees || [])[0];
    },
    reference() {
      return this.issue?.references?.relative;
    },
  },
};
</script>

<template>
  <div>
    <assignee class="block" :assignee="assignee" />

    <labels-select
      :selected-labels="issue.labels"
      variant="sidebar"
      class="block labels js-labels-block"
    >
      {{ __('None') }}
    </labels-select>
    <issue-reference v-if="reference" :reference="reference" />
  </div>
</template>

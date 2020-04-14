<script>
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';

export default {
  name: 'VulnerabilityFooter',
  components: { IssueNote, SolutionCard },
  props: {
    feedback: {
      type: Object,
      required: false,
      default: null,
    },
    project: {
      type: Object,
      required: true,
    },
    solutionInfo: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasIssue() {
      return Boolean(this.feedback?.issue_iid);
    },
    hasSolution() {
      return this.solutionInfo.solution || this.solutionInfo.hasRemediation;
    },
  },
};
</script>
<template>
  <div>
    <solution-card v-if="hasSolution" v-bind="solutionInfo" />
    <div v-if="hasIssue" class="card">
      <issue-note :feedback="feedback" :project="project" class="card-body" />
    </div>
    <hr />
  </div>
</template>

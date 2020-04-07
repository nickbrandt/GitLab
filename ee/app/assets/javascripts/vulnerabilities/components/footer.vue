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
  <ul class="notes">
    <li v-if="hasSolution" class="note">
      <solution-card v-bind="solutionInfo" />
    </li>
    <li>
      <hr />
    </li>
    <li v-if="hasIssue" class="note card my-4 border-bottom">
      <div class="card-body">
        <issue-note :feedback="feedback" :project="project" />
      </div>
    </li>
  </ul>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import HistoryEntry from './history_entry.vue';
import VulnerabilitiesEventBus from './vulnerabilities_event_bus';

export default {
  name: 'VulnerabilityFooter',
  components: { IssueNote, SolutionCard, HistoryEntry },
  props: {
    discussionsUrl: {
      type: String,
      required: true,
    },
    feedback: {
      type: Object,
      required: false,
      default: null,
    },
    notesUrl: {
      type: String,
      required: true,
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
    ...mapState(['discussionsDictionary', 'poll']),
    ...mapGetters(['discussions', 'notesDictionary']),
    hasIssue() {
      return Boolean(this.feedback?.issue_iid);
    },
    hasSolution() {
      return this.solutionInfo.solution || this.solutionInfo.hasRemediation;
    },
  },

  created() {
    this.fetchDiscussions({ discussionsUrl: this.discussionsUrl, notesUrl: this.notesUrl });

    VulnerabilitiesEventBus.$on('VULNERABILITY_STATE_CHANGE', () =>
      this.fetchDiscussions({
        discussionsUrl: this.discussionsUrl,
        notesUrl: this.notesUrl,
      }),
    );
  },

  beforeDestroy() {
    if (this.poll) this.poll.stop();
  },

  methods: {
    ...mapActions(['fetchDiscussions']),
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

    <ul v-if="discussions.length" ref="historyList" class="notes discussion-body">
      <history-entry
        v-for="discussion in discussions"
        :key="discussion.id"
        :discussion="discussion"
        :notes-url="notesUrl"
      />
    </ul>
  </div>
</template>

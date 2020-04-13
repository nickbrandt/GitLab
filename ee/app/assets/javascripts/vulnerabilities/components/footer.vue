<script>
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import HistoryEntry from './history_entry.vue';

export default {
  name: 'VulnerabilityFooter',
  components: { IssueNote, SolutionCard, HistoryEntry },
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

  data: () => ({
    discussions: [],
  }),

  computed: {
    hasIssue() {
      return Boolean(this.feedback?.issue_iid);
    },
    hasSolution() {
      return this.solutionInfo.solution || this.solutionInfo.hasRemediation;
    },
  },

  created() {
    // window.location.pathname is the URL without the protocol or hash/querystring
    // i.e. http://server/url?query=string#note_123 -> /server/url
    axios
      .get(joinPaths(window.location.pathname, 'discussions'))
      .then(({ data }) => {
        this.discussions = data;
      })
      .catch(() => {
        createFlash(
          s__(
            'VulnerabilityManagement|Something went wrong while trying to retrieve the vulnerability history. Please try again later.',
          ),
        );
      });
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

    <ul v-if="discussions.length" ref="historyList" class="notes">
      <history-entry
        v-for="discussion in discussions"
        :key="discussion.id"
        :discussion="discussion"
      />
    </ul>
  </div>
</template>

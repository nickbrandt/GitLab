<script>
import Visibility from 'visibilityjs';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import createFlash from '~/flash';
import { s__ } from '~/locale';
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
    timestamp: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      discussions: {},
      poll: null,
    };
  },

  computed: {
    discussionsValues() {
      return Object.values(this.discussions);
    },
    hasIssue() {
      return Boolean(this.feedback?.issue_iid);
    },
    hasSolution() {
      return this.solutionInfo.solution || this.solutionInfo.hasRemediation;
    },
  },

  created() {
    this.createNotesPoll();
    this.fetchDiscussions();

    VulnerabilitiesEventBus.$on('VULNERABILITY_STATE_CHANGE', this.fetchDiscussions);
  },

  beforeDestroy() {
    this.poll.stop();
  },

  methods: {
    fetchDiscussions() {
      axios
        .get(this.discussionsUrl)
        .then(({ data }) => {
          this.discussions = data.reduce((acc, curr) => {
            acc[curr.id] = curr;
            return acc;
          }, {});
        })
        .catch(() => {
          createFlash(
            s__(
              'VulnerabilityManagement|Something went wrong while trying to retrieve the vulnerability history. Please try again later.',
            ),
          );
        })
        .finally(() => {
          if (!Visibility.hidden()) {
            this.poll.enable();
            this.poll.makeRequest();
          }

          Visibility.change(() => {
            if (!Visibility.hidden()) {
              this.poll.restart();
            } else {
              this.poll.stop();
            }
          });
        });
    },
    createNotesPoll() {
      // Create headers object to update the X-Last-Fetched-At property on each update
      const headers = {
        'X-Last-Fetched-At': parseInt(this.timestamp, 10),
      };
      this.poll = new Poll({
        resource: {
          fetchNotes: data => axios(data),
        },
        method: 'fetchNotes',
        data: {
          method: 'get',
          url: this.notesUrl,
          headers,
        },
        successCallback: ({ data }) => {
          const { notes } = data;
          if (!notes.length) return;

          const updatedDiscussions = this.getUpdatedDiscussions(this.discussions, notes);

          this.discussions = { ...this.discussions, ...updatedDiscussions };
          headers['X-Last-Fetched-At'] = data.last_fetched_at;
        },
        errorCallback: () =>
          createFlash(
            s__(
              'VulnerabilityManagement|Something went wrong while fetching latest comments. Please try again later.',
            ),
          ),
      });
    },
    getUpdatedDiscussions(discussions, notes) {
      return notes.reduce((acc, note) => {
        const discussion = discussions[note.discussion_id];
        if (!discussion) {
          this.poll.stop();
          this.fetchDiscussions();
        } else {
          const newDiscussion = this.updateDiscussion(discussion, note);
          acc[newDiscussion.id] = newDiscussion;
        }
        return acc;
      }, {});
    },
    updateDiscussion(discussion, note) {
      const newDiscussion = { ...discussion };
      const { existingNote, index } = this.getExistingNote(discussion, note);

      if (existingNote) {
        newDiscussion.notes.splice(index, 1, note);
      } else {
        newDiscussion.notes.push(note);
      }

      return newDiscussion;
    },
    getExistingNote(discussion, note) {
      let index = -1;
      const existingNote = discussion.notes.find((dnote, i) => {
        if (dnote.id === note.id) {
          index = i;
          return true;
        }
        return false;
      });
      return { index, existingNote };
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

    <ul v-if="discussionsValues.length" ref="historyList" class="notes discussion-body">
      <history-entry
        v-for="discussion in discussionsValues"
        :key="discussion.id"
        :discussion="discussion"
        :notes-url="notesUrl"
      />
    </ul>
  </div>
</template>

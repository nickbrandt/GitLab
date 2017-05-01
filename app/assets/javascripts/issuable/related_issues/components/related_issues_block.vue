<script>
import eventHub from '../event_hub';
import IssueToken from './issue_token.vue';
import AddIssuableForm from './add_issuable_form.vue';

export default {
  name: 'RelatedIssuesBlock',

  props: {
    relatedIssues: {
      type: Array,
      required: false,
      default: [],
    },
    fetchError: {
      type: Error,
      required: false,
      default: null,
    },
    isAddRelatedIssuesFormVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    pendingRelatedIssues: {
      type: Array,
      required: false,
      default: [],
    },
    addRelatedIssuesFormInputValue: {
      type: String,
      required: false,
      default: '',
    },
  },

  components: {
    addIssuableForm: AddIssuableForm,
    issueToken: IssueToken,
  },

  computed: {
    relatedIssueCount() {
      return this.relatedIssues.length;
    },
    canAddRelatedIssues() {
      // TODO:
      return true;
    },
  },

  methods: {
    showAddRelatedIssuesForm() {
      eventHub.$emit('showAddRelatedIssuesForm');
    },
    onRelatedIssueRemoveRequest(reference) {
      eventHub.$emit('relatedIssueRemoveRequest', reference);
    },
  },
};
</script>

<template>
  <div
    class="panel-slim panel-default">
    <div class="panel-heading">
      <h3 class="panel-title">
        Related issues
        <div class="issue-count-holder">
          <span class="issue-count-holder-count has-btn">
            {{ relatedIssueCount }}
          </span>
          <button
            v-if="canAddRelatedIssues"
            class="issue-count-holder-add-button btn btn-small btn-default has-tooltip"
            type="button"
            aria-label="Add an issue"
            title="Add an issue"
            data-placement="top"
            @click="showAddRelatedIssuesForm">
            <i class="fa fa-plus" aria-hidden="true" />
          </button>
        </div>
      </h3>
    </div>
    <div
      v-if="isAddRelatedIssuesFormVisible"
      class="related-issues-add-related-issues-form panel-body">
      <addIssuableForm
        :input-value="addRelatedIssuesFormInputValue"
        :pending-issuables="pendingRelatedIssues"
        add-button-label="Add related issues" />
    </div>
    <div class="panel-body">
      <template v-if="fetchError">
        <i class="fa fa-exclamation-circle" aria-hidden="true" />
        An error occurred while fetching the related issues
      </template>
      <ul
        v-else-if="relatedIssues"
        class="related-issues-token-body">
        <li
          v-for="issue in relatedIssues"
          class="related-issues-token-list-item">
          <issueToken
            :reference="issue.reference"
            :title="issue.title"
            :path="issue.path"
            :state="issue.state"
            :canRemove="issue.canRemove"
            @removeRequest="onRelatedIssueRemoveRequest(issue.reference)" />
        </li>
      </ul>
      <template v-else>
        <i class="fa fa-spinner fa-spin" aria-hidden="true" />
        Fetching related issues
      </template>
      </div>
    </div>
  </div>
</template>

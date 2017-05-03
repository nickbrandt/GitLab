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
      default: () => [],
    },
    requestError: {
      type: String,
      required: false,
      default: null,
    },
    canAddRelatedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
    isAddRelatedIssuesFormVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    pendingRelatedIssues: {
      type: Array,
      required: false,
      default: () => [],
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
    hasRelatedIssues() {
      return this.relatedIssues.length > 0;
    },
    relatedIssueCount() {
      return this.relatedIssues.length;
    },
    panelHeadingClass() {
      return `panel-heading ${!this.hasRelatedIssues ? 'panel-empty-heading' : ''}`;
    },
    issueCountHolderCountClass() {
      return `issue-count-holder-count ${this.canAddRelatedIssues ? 'has-btn' : ''}`;
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
  <div class="related-issues-block">
    <div
      v-if="requestError"
      class="alert alert-danger">
      <i class="fa fa-exclamation-circle" aria-hidden="true" />
      {{ requestError }}
    </div>
    <div
      class="panel-slim panel-default">
      <div :class="panelHeadingClass">
        <h3 class="panel-title">
          Related issues
          <a
            href="TODO"
            aria-label="Read more about related issues">
            <i
              class="related-issues-header-help-icon fa fa-question-circle"
              aria-hidden="true" />
          </a>
          <div class="related-issues-header-issue-count issue-count-holder">
            <span :class="issueCountHolderCountClass">
              {{ relatedIssueCount }}
            </span>
            <button
              ref="issue-count-holder-add-button"
              v-if="canAddRelatedIssues"
              type="button"
              class="issue-count-holder-add-button btn btn-small btn-default has-tooltip"
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
        ref="related-issues-add-related-issues-form"
        v-if="isAddRelatedIssuesFormVisible"
        class="related-issues-add-related-issues-form panel-body">
        <add-issuable-form
          :input-value="addRelatedIssuesFormInputValue"
          :pending-issuables="pendingRelatedIssues"
          add-button-label="Add related issues" />
      </div>
      <div
        v-if="hasRelatedIssues"
        class="panel-body">
        <ul
          class="related-issues-token-body">
          <li
            :key="issue.reference"
            v-for="issue in relatedIssues"
            class="related-issues-token-list-item">
            <issue-token
              :reference="issue.reference"
              :title="issue.title"
              :path="issue.path"
              :state="issue.state"
              :can-remove="issue.canRemove"
              @removeRequest="onRelatedIssueRemoveRequest(issue.reference)" />
          </li>
        </ul>
        </div>
      </div>
    </div>
  </div>
</template>

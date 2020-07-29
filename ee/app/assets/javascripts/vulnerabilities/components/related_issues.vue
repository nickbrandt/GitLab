<script>
import axios from 'axios';
import RelatedIssuesStore from 'ee/related_issues/stores/related_issues_store';
import RelatedIssuesBlock from 'ee/related_issues/components/related_issues_block.vue';
import { issuableTypesMap, PathIdSeparator } from 'ee/related_issues/constants';
import { sprintf, __, s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import { RELATED_ISSUES_ERRORS } from '../constants';
import createFlash from '~/flash';
import { getFormattedIssue, getAddRelatedIssueRequestParams } from '../helpers';

export default {
  name: 'VulnerabilityRelatedIssues',
  components: { RelatedIssuesBlock },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    canModifyRelatedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    projectPath: {
      type: String,
      required: true,
    },
    issueFeedback: {
      type: Object,
      required: false,
    },
  },
  data() {
    this.store = new RelatedIssuesStore();
    return {
      state: this.store.state,
      isFetching: false,
      isSubmitting: false,
      isFormVisible: false,
      inputValue: '',
    };
  },
  computed: {
    vulnerabilityProjectId() {
      return this.projectPath.replace(/^\//, ''); // Remove the leading slash, i.e. '/root/test' -> 'root/test'.
    },
    relatedIssues() {
      return this.state.relatedIssues.map(issue => ({
        ...issue,
        actionButtons: this.getActionButtonsForIssue(issue),
      }));
    },
  },
  created() {
    this.fetchRelatedIssues();
  },
  methods: {
    toggleFormVisibility() {
      this.isFormVisible = !this.isFormVisible;
    },
    resetForm() {
      this.isFormVisible = false;
      this.store.setPendingReferences([]);
      this.inputValue = '';
    },
    addRelatedIssue({ pendingReferences }) {
      this.processAllReferences(pendingReferences);
      this.isSubmitting = true;
      const errors = [];

      // The endpoint can only accept one issue, so we need to do a separate call for each pending reference.
      const requests = this.state.pendingReferences.map(reference => {
        return axios
          .post(
            this.endpoint,
            getAddRelatedIssueRequestParams(reference, this.vulnerabilityProjectId),
          )
          .then(({ data }) => {
            const issue = getFormattedIssue(data.issue);
            // When adding an issue, the issue returned by the API doesn't have the vulnerabilityLinkId property; it's
            // instead in a separate ID property. We need to add it back in, or else the issue can't be deleted until
            // the page is refreshed.
            issue.vulnerabilityLinkId = issue.vulnerabilityLinkId ?? data.id;
            const index = this.state.pendingReferences.indexOf(reference);
            this.removePendingReference(index);
            this.store.addRelatedIssues(issue);
          })
          .catch(({ response }) => {
            errors.push({
              issueReference: reference,
              errorMessage: response.data?.message ?? RELATED_ISSUES_ERRORS.ISSUE_ID_ERROR,
            });
          });
      });

      return Promise.all(requests).then(() => {
        this.isSubmitting = false;
        const hasErrors = Boolean(errors.length);
        this.isFormVisible = hasErrors;

        if (hasErrors) {
          const messages = errors.map(error => sprintf(RELATED_ISSUES_ERRORS.LINK_ERROR, error));
          createFlash(messages.join(' '));
        }
      });
    },
    removeRelatedIssue(idToRemove) {
      const issue = this.state.relatedIssues.find(({ id }) => id === idToRemove);

      axios
        .delete(joinPaths(this.endpoint, issue.vulnerabilityLinkId.toString()))
        .then(() => {
          this.store.removeRelatedIssue(issue);
        })
        .catch(() => {
          createFlash(RELATED_ISSUES_ERRORS.UNLINK_ERROR);
        });
    },
    fetchRelatedIssues() {
      this.isFetching = true;

      axios
        .get(this.endpoint)
        .then(({ data }) => {
          const issues = data.map(getFormattedIssue);
          this.store.setRelatedIssues(issues);
        })
        .catch(() => {
          createFlash(__('An error occurred while fetching issues.'));
        })
        .finally(() => {
          this.isFetching = false;
        });
    },
    addPendingReferences({ untouchedRawReferences, touchedReference = '' }) {
      this.store.addPendingReferences(untouchedRawReferences);
      this.inputValue = touchedReference;
    },
    removePendingReference(indexToRemove) {
      this.store.removePendingRelatedIssue(indexToRemove);
    },
    processAllReferences(value = '') {
      const rawReferences = value.split(/\s+/).filter(reference => reference.trim().length > 0);
      this.addPendingReferences({ untouchedRawReferences: rawReferences });
    },
    getActionButtonsForIssue(issue) {
      // if we can't modify issues, no buttons at all
      if (!this.canModifyRelatedIssues) {
        return undefined;
      }

      // if the issue is the same as the vulnerability issue, lock icon
      if (this.issueFeedback?.issue_iid === issue.id) {
        return [
          {
            icon: 'lock',
            tooltip: s__(
              'VulnerabilityManagement|Issues created from a vulnerability cannot be removed.',
            ),
            isDisabled: true,
          },
        ];
      }

      // otherwise, delete icon
      return [
        {
          icon: 'close',
          tooltip: __('Remove'),
          onClick: () => this.removeRelatedIssue(issue.id),
        },
      ];
    },
  },
  autoCompleteSources: gl?.GfmAutoComplete?.dataSources,
  issuableType: issuableTypesMap.ISSUE,
  pathIdSeparator: PathIdSeparator.Issue,
};
</script>

<template>
  <related-issues-block
    :help-path="helpPath"
    :is-fetching="isFetching"
    :is-submitting="isSubmitting"
    :related-issues="relatedIssues"
    :can-add="canModifyRelatedIssues"
    :pending-references="state.pendingReferences"
    :is-form-visible="isFormVisible"
    :input-value="inputValue"
    :auto-complete-sources="$options.autoCompleteSources"
    :issuable-type="$options.issuableType"
    :path-id-separator="$options.pathIdSeparator"
    :show-categorized-issues="false"
    @toggleAddRelatedIssuesForm="toggleFormVisibility"
    @addIssuableFormInput="addPendingReferences"
    @addIssuableFormBlur="processAllReferences"
    @addIssuableFormSubmit="addRelatedIssue"
    @addIssuableFormCancel="resetForm"
    @pendingIssuableRemoveRequest="removePendingReference"
  >
    <template #headerText>{{ __('Related issues') }}</template>
  </related-issues-block>
</template>

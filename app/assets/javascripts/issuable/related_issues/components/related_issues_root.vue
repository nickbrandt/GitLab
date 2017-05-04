<script>
import eventHub from '../event_hub';
import RelatedIssuesBlock from './related_issues_block.vue';
import RelatedIssuesStore from '../stores/related_issues_store';
import RelatedIssuesService from '../services/related_issues_service';
import {
  ISSUABLE_REFERENCE_RE,
  getReferencePieces,
  assembleFullIssuableReference,
} from '../../../lib/utils/issuable_reference_utils';

export default {
  name: 'RelatedIssuesRoot',

  props: {
    endpoint: {
      type: String,
      required: true,
    },
    currentNamespacePath: {
      type: String,
      required: true,
    },
    currentProjectPath: {
      type: String,
      required: true,
    },
    canAddRelatedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  data() {
    this.store = new RelatedIssuesStore();

    return {
      state: this.store.state,
      isAddRelatedIssuesFormVisible: false,
    };
  },

  components: {
    relatedIssuesBlock: RelatedIssuesBlock,
  },

  computed: {
    computedRelatedIssues() {
      return this.store.getIssuesFromReferences(
        this.state.relatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
    computedPendingRelatedIssues() {
      return this.store.getIssuesFromReferences(
        this.state.pendingRelatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
  },

  methods: {
    onRelatedIssueRemoveRequest(reference) {
      const fullReference = assembleFullIssuableReference(
        reference,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
      this.store.setRelatedIssues(this.state.relatedIssues.filter(ref => ref !== fullReference));

      // Reset request error
      this.store.setRequestError(null);

      RelatedIssuesService.removeRelatedIssue(
        this.state.issueMap[fullReference].destroy_relation_path,
      )
        .catch((err) => {
          // Restore issue we were unable to delete
          this.store.setRelatedIssues(this.state.relatedIssues.concat(fullReference));

          this.store.setRequestError('An error occurred while removing related issues.');
          throw err;
        });
    },
    onShowAddRelatedIssuesForm() {
      this.isAddRelatedIssuesFormVisible = true;
    },
    onAddIssuableFormInput(newValue, caretPos) {
      const rawReferences = newValue.split(/\s/);

      let touchedReference;
      let iteratingPos = 0;
      const untouchedReferences = rawReferences.filter((reference) => {
        let isTouched = false;
        if (caretPos >= iteratingPos && caretPos <= (iteratingPos + reference.length)) {
          touchedReference = reference;
          isTouched = true;
        }

        iteratingPos = iteratingPos + reference.length + 1;
        return !isTouched;
      });

      const results = this.processIssuableReferences(untouchedReferences);
      if (results.fullReferences.length > 0) {
        this.store.setPendingRelatedIssues(
          _.uniq(this.state.pendingRelatedIssues.concat(results.fullReferences)),
        );
        this.store.setAddRelatedIssuesFormInputValue(`${results.unprocessableReferences.map(ref => `${ref} `).join('')}${touchedReference}`);
      }
    },
    onAddIssuableFormBlur(newValue) {
      const rawReferences = newValue.split(/\s+/);
      const results = this.processIssuableReferences(rawReferences);
      this.store.setPendingRelatedIssues(
        _.uniq(this.state.pendingRelatedIssues.concat(results.fullReferences)),
      );
      this.store.setAddRelatedIssuesFormInputValue(`${results.unprocessableReferences.join(' ')}`);
    },
    onAddIssuableFormIssuableRemoveRequest(reference) {
      const fullReference = assembleFullIssuableReference(
        reference,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
      this.store.setPendingRelatedIssues(
        this.state.pendingRelatedIssues.filter(ref => ref !== fullReference),
      );
    },
    onAddIssuableFormSubmit() {
      // Reset request error
      this.store.setRequestError(null);

      const currentPendingIssues = this.state.pendingRelatedIssues;
      this.service.addRelatedIssues(currentPendingIssues)
        .then(() => {
          this.store.setRelatedIssues(this.state.relatedIssues.concat(currentPendingIssues));
        })
        .catch((err) => {
          // Restore issues we were unable to submit
          this.store.setPendingRelatedIssues(
            _.uniq(this.state.pendingRelatedIssues.concat(currentPendingIssues)),
          );

          this.store.setRequestError('An error occurred while submitting related issues.');
          throw err;
        });
      this.store.setPendingRelatedIssues([]);
    },
    onAddIssuableFormCancel() {
      this.isAddRelatedIssuesFormVisible = false;
      this.store.setPendingRelatedIssues([]);
      this.store.setAddRelatedIssuesFormInputValue('');
    },
    fetchRelatedIssues() {
      // Reset request error
      this.store.setRequestError(null);

      this.service.fetchRelatedIssues()
        .then((issues) => {
          const relatedIssueReferences = issues.map((issue) => {
            const referenceKey = assembleFullIssuableReference(
              issue.reference,
              this.currentNamespacePath,
              this.currentProjectPath,
            );

            this.store.addToIssueMap(referenceKey, issue);

            return referenceKey;
          });
          this.store.setRelatedIssues(relatedIssueReferences);
        })
        .catch((err) => {
          this.store.setRequestError('An error occurred while fetching related issues.');
          throw err;
        });
    },
    processIssuableReferences(rawReferences) {
      const unprocessableReferences = [];
      const fullReferences = rawReferences
        .filter((reference) => {
          const isValidReference = ISSUABLE_REFERENCE_RE.test(reference);
          if (!isValidReference) {
            unprocessableReferences.push(reference);
          }

          return isValidReference;
        })
        .map(reference => assembleFullIssuableReference(
          reference,
          this.currentNamespacePath,
          this.currentProjectPath,
        ));

      // Add some temporary placeholders to lookup
      fullReferences.forEach((reference) => {
        if (!this.state.issueMap[reference]) {
          this.store.addToIssueMap(reference, {
            reference,
            fetchStatus: RelatedIssuesService.FETCHING_STATUS,
          });

          // Reset request error
          this.store.setRequestError(null);

          const referencePieces = getReferencePieces(reference);
          const baseIssueEndpoint = `/${referencePieces.namespace}/${referencePieces.project}/issues/${referencePieces.issue}`;
          RelatedIssuesService.fetchIssueInfo(`${baseIssueEndpoint}.json`)
            .then((issue) => {
              this.store.addToIssueMap(reference, {
                path: baseIssueEndpoint,
                reference,
                state: issue.state,
                title: issue.title,
              });
            })
            .catch((err) => {
              this.store.setRequestError('An error occurred while fetching issue info.');
              throw err;
            });
        }
      });

      return {
        unprocessableReferences,
        fullReferences,
      };
    },
  },

  created() {
    eventHub.$on('relatedIssueRemoveRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$on('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
    eventHub.$on('addIssuableFormInput', this.onAddIssuableFormInput);
    eventHub.$on('addIssuableFormBlur', this.onAddIssuableFormBlur);
    eventHub.$on('addIssuableFormIssuableRemoveRequest', this.onAddIssuableFormIssuableRemoveRequest);
    eventHub.$on('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
    eventHub.$on('addIssuableFormCancel', this.onAddIssuableFormCancel);

    this.service = new RelatedIssuesService(this.endpoint);
    this.fetchRelatedIssues();
  },

  beforeDestroy() {
    eventHub.$off('relatedIssueRemoveRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$off('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
    eventHub.$off('addIssuableFormInput', this.onAddIssuableFormInput);
    eventHub.$off('addIssuableFormBlur', this.onAddIssuableFormBlur);
    eventHub.$off('addIssuableFormIssuableRemoveRequest', this.onAddIssuableFormIssuableRemoveRequest);
    eventHub.$off('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
    eventHub.$off('addIssuableFormCancel', this.onAddIssuableFormCancel);
  },
};
</script>

<template>
  <related-issues-block
    :related-issues="computedRelatedIssues"
    :request-error="state.requestError"
    :canAddRelatedIssues="canAddRelatedIssues"
    :is-add-related-issues-form-visible="isAddRelatedIssuesFormVisible"
    :pending-related-issues="computedPendingRelatedIssues"
    :add-related-issues-form-input-value="state.addRelatedIssuesFormInputValue" />
</template>

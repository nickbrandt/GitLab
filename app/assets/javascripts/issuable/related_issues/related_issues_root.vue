<script>
import eventHub from './event_hub';
import RelatedIssuesBlock from './components/related_issues_block.vue';
import RelatedIssuesStore from './stores/related_issues_store';
import RelatedIssuesService from './services/related_issues_service';
import {
  ISSUABLE_REFERENCE_RE,
  getReferencePieces,
  assembleFullIssuableReference,
} from '../../lib/utils/issuable_reference_utils';

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
  },

  data() {
    this.store = new RelatedIssuesStore();

    return this.store.state;
  },

  components: {
    relatedIssuesBlock: RelatedIssuesBlock,
  },

  computed: {
    computedRelatedIssues() {
      return this.store.getIssuesFromReferences(
        this.relatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
    computedPendingRelatedIssues() {
      return this.store.getIssuesFromReferences(
        this.pendingRelatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
  },

  methods: {
    bindEvents() {
      eventHub.$on('relatedIssueRemoveRequest', this.onRelatedIssueRemoveRequest);
      eventHub.$on('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
      eventHub.$on('addIssuableFormInput', this.onAddIssuableFormInput);
      eventHub.$on('addIssuableFormIssuableRemoveRequest', this.onAddIssuableFormIssuableRemoveRequest);
      eventHub.$on('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
      eventHub.$on('addIssuableFormCancel', this.onAddIssuableFormCancel);
    },
    unbindEvents() {
      eventHub.$off('relatedIssueRemoveRequest', this.onRelatedIssueRemoveRequest);
      eventHub.$off('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
      eventHub.$off('addIssuableFormInput', this.onAddIssuableFormInput);
      eventHub.$off('addIssuableFormIssuableRemoveRequest', this.onAddIssuableFormIssuableRemoveRequest);
      eventHub.$off('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
      eventHub.$off('addIssuableFormCancel', this.onAddIssuableFormCancel);
    },
    onRelatedIssueRemoveRequest(reference) {
      const fullReference = assembleFullIssuableReference(
        reference,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
      this.store.setRelatedIssues(this.relatedIssues.filter(ref => ref !== fullReference));
      RelatedIssuesService.removeRelatedIssue(this.issueMap[fullReference].destroy_relation_path)
        .catch((err) => {
          // Restore issue we were unable to delete
          this.store.setRelatedIssues(this.relatedIssues.concat(fullReference));
          // TODO: Show error, err
        });
    },
    onShowAddRelatedIssuesForm() {
      this.store.setIsAddRelatedIssuesFormVisible(true);
    },
    onAddIssuableFormInput(newValue) {
      const references = newValue.split(/\s+/);
      const unprocessableReferences = [];
      const fullReferences = newValue.split(/\s+/)
        .slice(0, -1)
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
      // TODO: We could fetch these issues and add some extra info
      fullReferences.forEach((reference) => {
        if (!this.issueMap[reference]) {
          this.store.addToIssueMap(reference, {
            reference,
            fetchStatus: RelatedIssuesService.FETCHING_STATUS,
          });

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
              // TODO: Show error, err
            });
        }
      });
      this.store.setPendingRelatedIssues(this.pendingRelatedIssues.concat(fullReferences));
      this.store.setAddRelatedIssuesFormInputValue(`${unprocessableReferences.join(' ')} ${references.slice(-1)[0]}`);
    },
    onAddIssuableFormIssuableRemoveRequest(reference) {
      const fullReference = assembleFullIssuableReference(
        reference,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
      this.store.setPendingRelatedIssues(
        this.pendingRelatedIssues.filter(ref => ref !== fullReference),
      );
    },
    onAddIssuableFormSubmit() {
      const currentPendingIssues = this.pendingRelatedIssues;
      this.service.addRelatedIssues(currentPendingIssues)
        .then(() => {
          this.store.setRelatedIssues(this.relatedIssues.concat(currentPendingIssues));
        })
        .catch((err) => {
          // Restore issues we were unable to submit
          this.store.setPendingRelatedIssues(
            _.uniq(this.pendingRelatedIssues.concat(currentPendingIssues)),
          );
          // TODO: Show error, err
        });
      this.store.setPendingRelatedIssues([]);
    },
    onAddIssuableFormCancel() {
      this.store.setIsAddRelatedIssuesFormVisible(false);
      this.store.setPendingRelatedIssues([]);
      this.store.setAddRelatedIssuesFormInputValue('');
    },
    fetchRelatedIssues() {
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
          this.store.setFetchError(err);
        });
    },
  },

  created() {
    this.service = new RelatedIssuesService(this.endpoint);
    this.bindEvents();

    this.fetchRelatedIssues();
  },

  beforeDestroy() {
    this.unbindEvents();
  },
};
</script>

<template>
  <relatedIssuesBlock
    :related-issues="computedRelatedIssues"
    :fetch-error="fetchError"
    :is-add-related-issues-form-visible="isAddRelatedIssuesFormVisible"
    :pending-related-issues="computedPendingRelatedIssues"
    :add-related-issues-form-input-value="addRelatedIssuesFormInputValue" />
</template>

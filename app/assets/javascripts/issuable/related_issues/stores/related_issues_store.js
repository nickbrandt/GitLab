import { assembleFullIssuableReference, assembleNecessaryIssuableReference } from '../../../lib/utils/issuable_reference_utils';

class RelatedIssuesStore {
  constructor(initialState = {}) {
    this.state = Object.assign({
      issueMap: {},
      relatedIssues: [],
      pendingRelatedIssues: [],
      fetchError: null,
      isAddRelatedIssuesFormVisible: false,
      addRelatedIssuesFormInputValue: '',
    }, initialState);
  }

  getIssuesFromReferences(references, namespacePath, projectPath) {
    return references.map((reference) => {
      const referenceKey = assembleFullIssuableReference(
        reference,
        namespacePath,
        projectPath,
      );
      const displayReference = assembleNecessaryIssuableReference(
        reference,
        namespacePath,
        projectPath,
      );
      return {
        ...this.state.issueMap[referenceKey],
        reference: displayReference,
      };
    });
  }

  addToIssueMap(reference, issue) {
    this.state.issueMap[reference] = issue;
  }

  setRelatedIssues(value) {
    this.state.relatedIssues = value;
  }

  addPendingRelatedIssues(issues) {
    this.state.pendingRelatedIssues = this.state.pendingRelatedIssues.concat(issues);
  }

  setFetchError(value) {
    this.state.fetchError = value;
  }

  setIsAddRelatedIssuesFormVisible(value) {
    this.state.isAddRelatedIssuesFormVisible = value;
  }

  setAddRelatedIssuesFormInputValue(value) {
    this.state.addRelatedIssuesFormInputValue = value;
  }
}

export default RelatedIssuesStore;

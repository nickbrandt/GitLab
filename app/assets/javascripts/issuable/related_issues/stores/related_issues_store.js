import { assembleFullIssuableReference, assembleNecessaryIssuableReference } from '../../../lib/utils/issuable_reference_utils';

class RelatedIssuesStore {
  constructor(initialState = {}) {
    this.state = Object.assign({
      issueMap: {},
      relatedIssues: [],
      pendingRelatedIssues: [],
      requestError: null,
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
      const issueEntry = this.state.issueMap[referenceKey];

      return {
        path: issueEntry.path,
        reference: displayReference,
        title: issueEntry.title,
        state: issueEntry.state,
        canRemove: !!issueEntry.destroy_relation_path,
      };
    });
  }

  addToIssueMap(reference, issue) {
    this.state.issueMap = {
      ...this.state.issueMap,
      [reference]: issue,
    };
  }

  setRelatedIssues(value) {
    this.state.relatedIssues = value;
  }

  setPendingRelatedIssues(issues) {
    this.state.pendingRelatedIssues = issues;
  }

  setRequestError(value) {
    this.state.requestError = value;
  }

  setAddRelatedIssuesFormInputValue(value) {
    this.state.addRelatedIssuesFormInputValue = value;
  }
}

export default RelatedIssuesStore;

class RelatedIssuesStore {
  constructor(initialState = {}) {
    this.state = Object.assign({
      relatedIssues: [],
      fetchError: null,
      isAddRelatedIssuesFormVisible: false,
    }, initialState);
  }

  setRelatedIssues(value) {
    this.state.relatedIssues = value;
  }

  setFetchError(value) {
    this.state.fetchError = value;
  }

  setIsAddRelatedIssuesFormVisible(value) {
    this.state.isAddRelatedIssuesFormVisible = value;
  }

}

export default RelatedIssuesStore;

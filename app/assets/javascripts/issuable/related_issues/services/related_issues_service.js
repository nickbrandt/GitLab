import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(endpoint);
  }

  static fetchIssueInfo(endpoint) {
    const issueResource = Vue.resource(endpoint);
    return issueResource.get()
      .then((res) => {
        const issue = res.json();
        return issue;
      });
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get()
      .then((res) => {
        const issues = res.json();
        return issues;
      });
  }

  addRelatedIssues(newIssueReferences) {
    return this.relatedIssuesResource.save({}, {
      issue_references: newIssueReferences,
    })
      .then((res) => {
        const resData = res.json();
        return resData;
      });
  }

  static removeRelatedIssue(endpoint) {
    const relatedIssueResource = Vue.resource(endpoint);
    return relatedIssueResource.remove()
      .then((res) => {
        const resData = res.json();
        return resData;
      });
  }
}
RelatedIssuesService.FETCHING_STATUS = 'FETCHING';

export default RelatedIssuesService;

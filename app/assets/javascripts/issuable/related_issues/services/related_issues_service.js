import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(endpoint);
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get()
      .then((res) => {
        const issues = res.data;
        if (!issues) {
          throw new Error('Response didn\'t return any issues data');
        }

        return issues;
      });
  }
}
RelatedIssuesService.FETCHING_STATUS = 'FETCHING';

export default RelatedIssuesService;

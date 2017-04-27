import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(`${endpoint}`);
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get()
      .then((res) => {
        const issues = res.data;
        if (!issues) {
          throw new Error('Response didn\'t include `service_desk_address`');
        }

        return issues;
      });
  }
}

export default RelatedIssuesService;

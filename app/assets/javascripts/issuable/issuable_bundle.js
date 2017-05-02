import Vue from 'vue';
import RelatedIssuesRoot from '../issuable/related_issues/components/related_issues_root.vue';
import './time_tracking/time_tracking_bundle';

document.addEventListener('DOMContentLoaded', () => {
  const relatedIssuesRootElement = document.querySelector('.js-related-issues-root');
  if (relatedIssuesRootElement) {
    // eslint-disable-next-line no-new
    new Vue({
      el: relatedIssuesRootElement,
      components: {
        relatedIssuesRoot: RelatedIssuesRoot,
      },
      render: createElement => createElement('relatedIssuesRoot', {
        props: {
          endpoint: relatedIssuesRootElement.dataset.endpoint,
          currentNamespacePath: relatedIssuesRootElement.dataset.namespace,
          currentProjectPath: relatedIssuesRootElement.dataset.project,
          canAddRelatedIssues: typeof relatedIssuesRootElement.dataset.canAddRelatedIssues !== 'undefined' &&
            relatedIssuesRootElement.dataset.canAddRelatedIssues !== 'false',
        },
      }),
    });
  }
});

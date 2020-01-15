import Vue from 'vue';
import createStore from './store';
import CodeAnalyticsApp from './components/app.vue';
import FilteredSearchCodeReviewAnalytics from './filtered_search_code_review_analytics';

export default () => {
  const container = document.getElementById('js-code-review-analytics');
  const { projectId } = container.dataset;

  if (!container) return;

  // eslint-disable-next-line no-new
  new Vue({
    el: container,
    store: createStore(),
    created() {
      this.filterManager = new FilteredSearchCodeReviewAnalytics();
      this.filterManager.setup();
    },
    render(h) {
      return h(CodeAnalyticsApp, {
        props: {
          projectId: Number(projectId),
        },
      });
    },
  });
};

import Vue from 'vue';
import GroupRepositoryAnalytics from './components/group_repository_analytics.vue';

export default () => {
  const el = document.querySelector('#js-group-repository-analytics');
  const { groupAnalyticsCoverageReportsPath } = el?.dataset || {};

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      GroupRepositoryAnalytics,
    },
    render(createElement) {
      return createElement('group-repository-analytics', {
        props: {
          groupAnalyticsCoverageReportsPath,
        },
      });
    },
  });
};

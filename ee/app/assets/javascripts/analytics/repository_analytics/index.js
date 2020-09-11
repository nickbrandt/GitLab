import Vue from 'vue';
import GroupRepositoryAnalytics from './components/group_repository_analytics.vue';

export default () => {
  const el = document.querySelector('#js-group-repository-analytics');
  const { groupAnalyticsCoverageReportsPath } = el?.dataset || {};

  if (el) {
    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        GroupRepositoryAnalytics,
      },
      provide: {
        groupAnalyticsCoverageReportsPath,
      },
      render(createElement) {
        return createElement('group-repository-analytics', {});
      },
    });
  }
};

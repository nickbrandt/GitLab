import Vue from 'vue';
import EnvironmentDashboardComponent from 'ee/environments_dashboard/components/dashboard/dashboard.vue';

document.addEventListener(
  'DOMContentLoaded',
  () =>
    new Vue({
      el: '#js-environments',
      components: {
        EnvironmentDashboardComponent,
      },
      render(createElement) {
        return createElement(EnvironmentDashboardComponent, {
          props: {
            listPath: this.$el.dataset.listPath,
            addPath: this.$el.dataset.addPath,
            emptyDashboardSvgPath: this.$el.dataset.emptyDashboardSvgPath,
            emptyDashboardHelpPath: this.$el.dataset.emptyDashboardHelpPath,
          },
        });
      },
    }),
);

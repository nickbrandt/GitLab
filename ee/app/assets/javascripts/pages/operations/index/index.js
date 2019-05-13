import Vue from 'vue';
import createStore from 'ee/vue_shared/dashboards/store';
import DashboardComponent from 'ee/operations/components/dashboard/dashboard.vue';

document.addEventListener(
  'DOMContentLoaded',
  () =>
    new Vue({
      el: '#js-operations',
      store: createStore(),
      components: {
        DashboardComponent,
      },
      render(createElement) {
        return createElement(DashboardComponent, {
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

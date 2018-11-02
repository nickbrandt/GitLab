import Vue from 'vue';
import store from 'ee/operations/store';
import DashboardComponent from 'ee/operations/components/dashboard/dashboard.vue';

document.addEventListener(
  'DOMContentLoaded',
  () =>
    new Vue({
      el: '#js-operations',
      store,
      components: {
        DashboardComponent,
      },
      render(createElement) {
        return createElement(DashboardComponent, {
          props: {
            listPath: this.$el.dataset.listPath,
            addPath: this.$el.dataset.addPath,
            emptyDashboardSvgPath: this.$el.dataset.emptyDashboardSvgPath,
          },
        });
      },
    }),
);

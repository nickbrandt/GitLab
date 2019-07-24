import Vue from 'vue';
import ProductivityAnalyticsApp from './components/app.vue';

export default function(el) {
  if (!el) {
    return false;
  }

  return new Vue({
    el,
    components: {
      ProductivityAnalyticsApp,
    },
    render(h) {
      return h(ProductivityAnalyticsApp, {
        props: {},
      });
    },
  });
}

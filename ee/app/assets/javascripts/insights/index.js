import Vue from 'vue';
import Insights from './components/insights.vue';
import store from './stores';

export default () => {
  const el = document.querySelector('#js-insights-pane');

  if (!el) return null;

  return new Vue({
    el,
    store,
    components: {
      Insights,
    },
    render(createElement) {
      return createElement('insights', {
        props: {
          endpoint: el.dataset.endpoint,
          queryEndpoint: el.dataset.queryEndpoint,
        },
      });
    },
  });
};

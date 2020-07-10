import Vue from 'vue';
import InsightsEmbedded from './components/insights_embedded.vue';
import createRouter from './insights_embedded_router';
import store from '../insights/stores';

export default () => {
  const el = document.querySelector('#js-insights-pane');
  const { endpoint, queryEndpoint, notice } = el.dataset;
  const router = createRouter(endpoint);

  if (!el) return null;

  return new Vue({
    el,
    store,
    router,
    components: {
      InsightsEmbedded,
    },
    render(createElement) {
      return createElement('insights-embedded', {
        props: {
          endpoint,
          queryEndpoint,
          notice,
        },
      });
    },
  });
};

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import MergeRequestAnalyticsApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-merge-request-analytics-app');

  if (!el) return false;

  const { fullPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    name: 'MergeRequestAnalyticsApp',
    provide: {
      fullPath,
    },
    render: createElement => createElement(MergeRequestAnalyticsApp),
  });
};

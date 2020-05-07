import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import Iterations from './components/iterations.vue';

Vue.use(VueApollo);

export default function initIterationsList(el) {
  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(Iterations, {
        props: {
          groupPath: el.dataset.groupFullPath,
          canAdmin: parseBoolean(el.dataset.canAdmin),
        },
      });
    },
  });
};

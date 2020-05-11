import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import Iterations from './components/iterations.vue';
import IterationForm from './components/iteration_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default function initIterationsList() {
  const el = document.querySelector('.js-iterations-list');
  
  if (!el) {
    return null;
  }

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(Iterations, {
        props: {
          groupPath: el.dataset.groupFullPath,
          canAdmin: parseBoolean(el.dataset.canAdmin),
          newIterationPath: el.dataset.newIterationPath,
        },
      });
    },
  });
};

export function initIterationForm() {
  const el = document.querySelector('.js-iteration-new');
  
  if (!el) {
    return null;
  }

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(IterationForm, {
        props: {
          groupPath: el.dataset.groupFullPath,
          previewMarkdownPath: el.dataset.previewMarkdownPath,
        },
      });
    },
  });
}
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import IterationForm from './components/iteration_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

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
          iterationsListPath: el.dataset.iterationsListPath,
        },
      });
    },
  });
}

export default {};

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import EpicForm from './components/epic_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export function initEpicForm() {
  const el = document.querySelector('.js-epic-new');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(EpicForm, {
        props: {
          groupPath: el.dataset.groupFullPath,
          groupEpicsPath: el.dataset.groupEpicsPath,
          markdownPreviewPath: el.dataset.markdownPreviewPath,
          markdownDocsPath: el.dataset.markdownDocsPath,
        },
      });
    },
  });
}

export default {};

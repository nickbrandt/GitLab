import Vue from 'vue';
import DependenciesApp from './components/app.vue';
import createStore from './store';
import { DEPENDENCY_LIST_TYPES } from './store/constants';
import { addListType } from './store/utils';

export default () => {
  const el = document.querySelector('#js-dependencies-app');
  const { endpoint, emptyStateSvgPath, documentationPath, supportDocumentationPath } = el.dataset;

  const store = createStore();

  return new Vue({
    el,
    store,
    components: {
      DependenciesApp,
    },
    render(createElement) {
      return createElement(DependenciesApp, {
        props: {
          endpoint,
          emptyStateSvgPath,
          documentationPath,
          supportDocumentationPath,
        },
      });
    },
  });
};

import Vue from 'vue';
import ProjectLicensesApp from './components/app.vue';
import createStore from './store';
import { LICENSE_LIST } from './store/constants';

export default () => {
  const el = document.querySelector('#js-licenses-app');
  const { endpoint, emptyStateSvgPath, documentationPath } = el.dataset;
  const store = createStore();
  store.dispatch(`${LICENSE_LIST}/setLicensesEndpoint`, endpoint);

  return new Vue({
    el,
    store,
    components: {
      ProjectLicensesApp,
    },
    render(createElement) {
      return createElement(ProjectLicensesApp, {
        props: {
          emptyStateSvgPath,
          documentationPath,
        },
      });
    },
  });
};

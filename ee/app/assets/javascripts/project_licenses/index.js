import Vue from 'vue';
import ProjectLicensesApp from './components/app.vue';
import createStore from './store';
import { LICENSE_LIST } from './store/constants';

export default () => {
  const el = document.querySelector('#js-licenses-app');
  const {
    projectLicensesEndpoint,
    emptyStateSvgPath,
    documentationPath,
    readLicensePoliciesEndpoint,
    writeLicensePoliciesEndpoint,
  } = el.dataset;
  const store = createStore();
  store.dispatch('licenseManagement/setIsAdmin', Boolean(writeLicensePoliciesEndpoint));
  store.dispatch(`${LICENSE_LIST}/setLicensesEndpoint`, projectLicensesEndpoint);

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
          readLicensePoliciesEndpoint,
        },
      });
    },
  });
};

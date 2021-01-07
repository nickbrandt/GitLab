import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
import Form from './components/form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const createComplianceFrameworksFormApp = (el) => {
  if (!el) {
    return false;
  }

  const { fullPath, id = null } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(Form, {
        props: {
          fullPath,
          id,
        },
      });
    },
  });
};

export { createComplianceFrameworksFormApp };

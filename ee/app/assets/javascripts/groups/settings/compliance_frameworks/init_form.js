import Vue from 'vue';
import VueApollo from 'vue-apollo';

import Form from './components/form.vue';
import createDefaultClient, { fetchPolicies } from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { fetchPolicy: fetchPolicies.NO_CACHE }),
});

const createComplianceFrameworksFormApp = (el) => {
  if (!el) {
    return false;
  }

  const { groupEditPath, groupPath, frameworkId: id = null } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(Form, {
        props: {
          groupEditPath,
          groupPath,
          id,
        },
      });
    },
  });
};

export { createComplianceFrameworksFormApp };

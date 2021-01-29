import Vue from 'vue';
import VueApollo from 'vue-apollo';

import CreateForm from './components/create_form.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
});

const createComplianceFrameworksFormApp = (el) => {
  if (!el) {
    return false;
  }

  const { groupEditPath, groupPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      const element = CreateForm;
      const props = { groupEditPath, groupPath };

      return createElement(element, {
        props,
      });
    },
  });
};

export { createComplianceFrameworksFormApp };

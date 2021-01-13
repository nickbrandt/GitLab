import Vue from 'vue';

import createDefaultClient, { fetchPolicies } from '~/lib/graphql';
import Form from './components/form.vue';
import ComplianceFrameworksService from './services/compliance_frameworks_service';

const createComplianceFrameworksFormApp = (el) => {
  if (!el) {
    return false;
  }

  const { groupEditPath, groupPath, frameworkId: id = null } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(Form, {
        props: {
          groupEditPath,
          service: new ComplianceFrameworksService(
            createDefaultClient({}, { fetchPolicy: fetchPolicies.NO_CACHE }),
            groupPath,
            id,
          ),
        },
      });
    },
  });
};

export { createComplianceFrameworksFormApp };

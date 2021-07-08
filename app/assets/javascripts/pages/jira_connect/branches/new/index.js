import Vue from 'vue';
import VueApollo from 'vue-apollo';
import JiraConnectNewBranchForm from '~/jira_connect/branches/components/new_branch_form.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export async function initJiraConnectNewBranch() {
  const el = document.querySelector('.js-jira-connect-create-branch');
  if (!el) {
    return null;
  }

  const { formEndpoint } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        assumeImmutableResults: true,
      },
    ),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: { formEndpoint },
    render(createElement) {
      return createElement(JiraConnectNewBranchForm);
    },
  });
}

initJiraConnectNewBranch();

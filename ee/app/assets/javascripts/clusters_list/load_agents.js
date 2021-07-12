import createDefaultClient from '~/lib/graphql';
import Agents from './components/agents.vue';

export default (Vue, VueApollo) => {
  const el = document.querySelector('#js-cluster-agents-list');

  if (!el) {
    return null;
  }

  const defaultClient = createDefaultClient();

  const { emptyStateImage, defaultBranchName, projectPath, kasAddress } = el.dataset;

  return new Vue({
    el,
    apolloProvider: new VueApollo({ defaultClient }),
    provide: {
      emptyStateImage,
      defaultBranchName,
      projectPath,
      kasAddress,
    },
    render(createElement) {
      return createElement(Agents);
    },
  });
};

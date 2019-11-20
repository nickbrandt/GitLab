import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import CreateEksCluster from './components/create_eks_cluster.vue';
import createStore from './store';

Vue.use(Vuex);

export default el => {
  const {
    gitlabManagedClusterHelpPath,
    kubernetesIntegrationHelpPath,
    accountAndExternalIdsHelpPath,
    createRoleArnHelpPath,
    accessKeyId,
    secretAccessKey,
    sessionToken,
    externalId,
    accountId,
    instanceTypes,
    hasCredentials,
    createRolePath,
    createClusterPath,
    signOutPath,
    externalLinkIcon,
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({
      initialState: {
        hasCredentials: parseBoolean(hasCredentials),
        externalId,
        accountId,
        instanceTypes: JSON.parse(instanceTypes),
        createRolePath,
        createClusterPath,
        signOutPath,
      },
      awsCredentials: {
        accessKeyId,
        secretAccessKey,
        sessionToken,
      },
    }),
    components: {
      CreateEksCluster,
    },
    render(createElement) {
      return createElement('create-eks-cluster', {
        props: {
          gitlabManagedClusterHelpPath,
          kubernetesIntegrationHelpPath,
          accountAndExternalIdsHelpPath,
          createRoleArnHelpPath,
          externalLinkIcon,
        },
      });
    },
  });
};

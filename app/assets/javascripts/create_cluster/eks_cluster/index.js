import Vue from 'vue';
import Vuex from 'vuex';
import CreateEksCluster from './components/create_eks_cluster.vue';
import createStore from './store';

Vue.use(Vuex);

export default el => {
  const { gitlabManagedClusterHelpPath, kubernetesIntegrationHelpPath } = el.dataset;

  return new Vue({
    el,
    store: createStore(),
    components: {
      CreateEksCluster,
    },
    data() {
      const {
        gitlabManagedClusterHelpPath,
        accountAndExternalIdsHelpPath,
        createRoleArnHelpPath,
        externalId,
        accountId,
        validCredentials,
      } = document.querySelector(this.$options.el).dataset;

      return {
        gitlabManagedClusterHelpPath,
        accountAndExternalIdsHelpPath,
        createRoleArnHelpPath,
        externalId,
        accountId,
        validCredentials,
      };
    },
    render(createElement) {
      return createElement('create-eks-cluster', {
        props: {
          gitlabManagedClusterHelpPath: this.gitlabManagedClusterHelpPath,
          accountAndExternalIdsHelpPath: this.accountAndExternalIdsHelpPath,
          createRoleArnHelpPath: this.createRoleArnHelpPath,
          externalId: this.externalId,
          accountId: this.accountId,
          validCredentials: this.validCredentials,
        },
      });
    },
  });
};

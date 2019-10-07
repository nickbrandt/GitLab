import { shallowMount } from '@vue/test-utils';

import CreateEksCluster from '~/create_cluster/eks_cluster/components/create_eks_cluster.vue';
import EksClusterConfigurationForm from '~/create_cluster/eks_cluster/components/eks_cluster_configuration_form.vue';
import ServiceCredentialsForm from '~/create_cluster/eks_cluster/components/service_credentials_form.vue';

describe('CreateEksCluster', () => {
  let vm;
  const accountId = 'accountId';
  const externalId = 'externalId';
  const gitlabManagedClusterHelpPath = 'gitlab-managed-cluster-help-path';
  const accountAndExternalIdsHelpPath = 'account-and-external-id-help-path';
  const createRoleArnHelpPath = 'role-arn-help-path';

  beforeEach(() => {
    vm = shallowMount(CreateEksCluster, {
      propsData: {
        validCredentials: false,
        accountId,
        externalId,
        gitlabManagedClusterHelpPath,
        accountAndExternalIdsHelpPath,
        createRoleArnHelpPath,
      },
    });
  });
  afterEach(() => vm.destroy());

  describe('when credentials are valid', () => {
    beforeEach(() => {
      vm.setProps({ validCredentials: true });
    });

    it('displays eks cluster configuration form when credentials are valid', () => {
      expect(vm.find(EksClusterConfigurationForm).exists()).toBe(true);
    });

    it('provides gitlabManagedClusterHelpPath to eks cluster config form', () => {
      expect(vm.find(EksClusterConfigurationForm).props('gitlabManagedClusterHelpPath')).toBe(
        gitlabManagedClusterHelpPath,
      );
    });
  });

  describe('when credentials are invalid', () => {
    beforeEach(() => {
      vm.setProps({ validCredentials: false });
    });

    it('displays service credentials form', () => {
      expect(vm.find(ServiceCredentialsForm).exists()).toBe(true);
    });

    describe('passes to the service credentials form', () => {
      it('account id and external id', () => {
        expect(vm.find(ServiceCredentialsForm).props('externalId')).toBe(externalId);
        expect(vm.find(ServiceCredentialsForm).props('accountId')).toBe(accountId);
      });

      it('help url for account and external ids', () => {
        expect(vm.find(ServiceCredentialsForm).props('accountAndExternalIdsHelpPath')).toBe(
          accountAndExternalIdsHelpPath,
        );
      });

      it('help url to create a role ARN', () => {
        expect(vm.find(ServiceCredentialsForm).props('createRoleArnHelpPath')).toBe(
          createRoleArnHelpPath,
        );
      });
    });
  });
});

import { mount, shallowMount } from '@vue/test-utils';
import EnvironmentAlert from 'ee/environments/components/environment_alert.vue';
import DeployBoard from 'ee/environments/components/deploy_board_component.vue';
import CanaryUpdateModal from 'ee/environments/components/canary_update_modal.vue';
import EnvironmentTable from '~/environments/components/environments_table.vue';

describe('Environment table', () => {
  let wrapper;

  const factory = async (options = {}, m = mount) => {
    // This destroys any wrappers created before a nested call to factory reassigns it
    if (wrapper && wrapper.destroy) {
      wrapper.destroy();
    }
    wrapper = m(EnvironmentTable, {
      ...options,
    });
    await wrapper.vm.$nextTick();
    await jest.runOnlyPendingTimers();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render the alert if there is one', async () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      logs_path: 'url',
      id: 1,
      hasDeployBoard: false,
      has_opened_alert: true,
    };

    await factory(
      {
        propsData: {
          environments: [mockItem],
          canReadEnvironment: true,
          canaryDeploymentFeatureId: 'canary_deployment',
          showCanaryDeploymentCallout: true,
          userCalloutsPath: '/callouts',
          lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
          helpCanaryDeploymentsPath: 'help/canary-deployments',
        },
      },
      shallowMount,
    );

    expect(wrapper.find(EnvironmentAlert).exists()).toBe(true);
  });

  it('should set the enviornment to change and weight when a change canary weight event is recevied', async () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      logs_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: deployBoardMockData,
      isDeployBoardVisible: true,
      isLoadingDeployBoard: false,
      isEmptyDeployBoard: false,
    };

    await factory({
      propsData: {
        environments: [mockItem],
        canCreateDeployment: false,
        canReadEnvironment: true,
        canaryDeploymentFeatureId: 'canary_deployment',
        showCanaryDeploymentCallout: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
      },
    });

    wrapper.find(DeployBoard).vm.$emit('changeCanaryWeight', 40);
    await wrapper.vm.$nextTick();

    expect(wrapper.find(CanaryUpdateModal).props()).toMatchObject({
      weight: 40,
      environment: mockItem,
    });
  });
});

import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import environmentTableComp from '~/environments/components/environments_table.vue';
import eventHub from '~/environments/event_hub';
import { deployBoardMockData } from './mock_data';

describe('Environment table', () => {
  let Component;
  let vm;

  beforeEach(() => {
    Component = Vue.extend(environmentTableComp);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('Should render a table', () => {
    const mockItem = {
      name: 'review',
      folderName: 'review',
      size: 3,
      isFolder: true,
      environment_path: 'url',
    };

    vm = mountComponent(Component, {
      environments: [mockItem],
      canReadEnvironment: true,
      canaryDeploymentFeatureId: 'canary_deployment',
      showCanaryDeploymentCallout: true,
      userCalloutsPath: '/callouts',
      lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
      helpCanaryDeploymentsPath: 'help/canary-deployments',
    });

    expect(vm.$el.getAttribute('class')).toContain('ci-table');
  });

  it('should render deploy board container when data is provided', () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: deployBoardMockData,
      isDeployBoardVisible: true,
      isLoadingDeployBoard: false,
      isEmptyDeployBoard: false,
    };

    vm = mountComponent(Component, {
      environments: [mockItem],
      canCreateDeployment: false,
      canReadEnvironment: true,
      canaryDeploymentFeatureId: 'canary_deployment',
      showCanaryDeploymentCallout: true,
      userCalloutsPath: '/callouts',
      lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
      helpCanaryDeploymentsPath: 'help/canary-deployments',
    });

    expect(vm.$el.querySelector('.js-deploy-board-row')).toBeDefined();
    expect(vm.$el.querySelector('.deploy-board-icon')).not.toBeNull();
  });

  it('should toggle deploy board visibility when arrow is clicked', done => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: {
        instances: [{ status: 'ready', tooltip: 'foo' }],
        abort_url: 'url',
        rollback_url: 'url',
        completion: 100,
        is_completed: true,
      },
      isDeployBoardVisible: false,
    };

    eventHub.$on('toggleDeployBoard', env => {
      expect(env.id).toEqual(mockItem.id);
      done();
    });

    vm = mountComponent(Component, {
      environments: [mockItem],
      canReadEnvironment: true,
      canaryDeploymentFeatureId: 'canary_deployment',
      showCanaryDeploymentCallout: true,
      userCalloutsPath: '/callouts',
      lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
      helpCanaryDeploymentsPath: 'help/canary-deployments',
    });

    vm.$el.querySelector('.deploy-board-icon').click();
  });

  it('should render canary callout', () => {
    const mockItem = {
      name: 'review',
      folderName: 'review',
      size: 3,
      isFolder: true,
      environment_path: 'url',
      showCanaryCallout: true,
    };

    vm = mountComponent(Component, {
      environments: [mockItem],
      canCreateDeployment: false,
      canReadEnvironment: true,
      canaryDeploymentFeatureId: 'canary_deployment',
      showCanaryDeploymentCallout: true,
      userCalloutsPath: '/callouts',
      lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
      helpCanaryDeploymentsPath: 'help/canary-deployments',
    });

    expect(vm.$el.querySelector('.canary-deployment-callout')).not.toBeNull();
  });
});

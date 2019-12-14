import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { environmentsList } from 'spec/environments/mock_data';
import axios from '~/lib/utils/axios_utils';
import environmentsFolderViewComponent from '~/environments/folder/environments_folder_view.vue';

describe('Environments Folder View', () => {
  let Component;
  let component;
  let mock;

  const mockData = {
    endpoint: 'environments.json',
    folderName: 'review',
    canReadEnvironment: true,
    cssContainerClass: 'container',
    canaryDeploymentFeatureId: 'canary_deployment',
    showCanaryDeploymentCallout: true,
    userCalloutsPath: '/callouts',
    lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
    helpCanaryDeploymentsPath: 'help/canary-deployments',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    Component = Vue.extend(environmentsFolderViewComponent);
  });

  afterEach(() => {
    mock.restore();

    component.$destroy();
  });

  describe('successful request', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(
        200,
        {
          environments: environmentsList,
          stopped_count: 1,
          available_count: 0,
        },
        {
          'X-nExt-pAge': '2',
          'x-page': '1',
          'X-Per-Page': '2',
          'X-Prev-Page': '',
          'X-TOTAL': '20',
          'X-Total-Pages': '10',
        },
      );

      component = mountComponent(Component, mockData);
    });

    describe('deploy boards', () => {
      it('should render arrow to open deploy boards', done => {
        setTimeout(() => {
          expect(component.$el.querySelector('.folder-icon.ic-chevron-right')).not.toBeNull();
          done();
        }, 0);
      });
    });
  });
});

import { shallowMount, createLocalVue } from '@vue/test-utils';
import { getTimeago } from '~/lib/utils/datetime_utility';
import DeploymentInfo from '~/vue_merge_request_widget/components/deployment_info.vue';
import MemoryUsage from '~/vue_merge_request_widget/components/deployment_info.vue';

import { SUCCESS } from '~/vue_merge_request_widget/components/constants';

const deploymentMockData = {
      id: 15,
      name: 'review/diplo',
      url: '/root/review-apps/environments/15',
      stop_url: '/root/review-apps/environments/15/stop',
      metrics_url: '/root/review-apps/environments/15/deployments/1/metrics',
      metrics_monitoring_url: '/root/review-apps/environments/15/metrics',
      external_url: 'http://gitlab.com.',
      external_url_formatted: 'gitlab',
      deployed_at: '2017-03-22T22:44:42.258Z',
      deployed_at_formatted: 'Mar 22, 2017 10:44pm',
      deployment_manual_actions: [],
      status: SUCCESS,
      changes: [
        {
          path: 'index.html',
          external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/index.html',
        },
        {
          path: 'imgs/gallery.html',
          external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
        },
        {
          path: 'about/',
          external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/about/',
        },
      ],
    };



describe('Deployment Info', () => {

  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(DeploymentInfo), {
      localVue,
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        computedDeploymentStatus: SUCCESS,
        deployment: deploymentMockData,
        showMetrics: false
      }
    })
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('deployment name', () => {
    it('renders deployment name', () => {
      expect(wrapper.find('.js-deploy-meta').attributes().href).toEqual(
        deploymentMockData.url
      );

      expect(wrapper.find('.js-deploy-meta').text()).toContain(deploymentMockData.name);
    });
  });

  describe('deployTimeago', () => {
    it('return formatted date', () => {
      const readable = getTimeago().format(deploymentMockData.deployed_at);

      expect(wrapper.vm.deployTimeago).toEqual(readable);
      expect(wrapper.find('.js-deploy-time').text()).toEqual(readable);
    });
  });

  describe('hasDeploymentTime', () => {
    describe('when deployment has both deployed_at and deployed_at_formatted', () => {
      it('should return true', () => {
        expect(wrapper.vm.hasDeploymentTime).toEqual(true);
        expect(wrapper.find('.js-deploy-time').exists()).toBe(true);
      });
    });

    describe('when deployment does has no deployed_at', () => {
      it('should return false', () => {

        factory({
          propsData: {
            computedDeploymentStatus: SUCCESS,
            deployment: {...deploymentMockData, deployed_at: null },
            showMetrics: false
          }
        });

        expect(wrapper.vm.hasDeploymentTime).toEqual(false);
        expect(wrapper.find('.js-deploy-time').exists()).toBe(false);
      });
    });


    describe('when deployment does has no deployed_at_formatted', () => {
      it('should return false', () => {

        factory({
          propsData: {
            computedDeploymentStatus: SUCCESS,
            deployment: {...deploymentMockData, deployed_at_formatted: null },
            showMetrics: false
          }
        });

        expect(wrapper.vm.hasDeploymentTime).toEqual(false);
        expect(wrapper.find('.js-deploy-time').exists()).toBe(false);
      });
    });
  });

  describe('hasDeploymentMeta', () => {
    describe('when deployment has both name and url', () => {
      it('should return true', () => {
        expect(wrapper.vm.hasDeploymentMeta).toEqual(true);
        expect(wrapper.find('.js-deploy-meta').exists()).toBe(true);
      });

      describe('when deployment has no url', () => {
        factory({
          propsData: {
            computedDeploymentStatus: SUCCESS,
            deployment: {...deploymentMockData, url: null },
            showMetrics: false
          }
        });

        expect(wrapper.vm.hasDeploymentMeta).toEqual(false);
        expect(wrapper.find('.js-deploy-meta').exists()).toBe(false);

      });

      describe('when deployment has no name', () => {
        factory({
          propsData: {
            computedDeploymentStatus: SUCCESS,
            deployment: {...deploymentMockData, name: null },
            showMetrics: false
          }
        });

        expect(wrapper.vm.hasDeploymentMeta).toEqual(false);
        expect(wrapper.find('.js-deploy-meta').exists()).toBe(false);

      });
    });
  });

  describe('metrics', () => {
    describe('with showMetrics enabled', () => {

      beforeEach(() => {
        factory({
          propsData: {
            computedDeploymentStatus: SUCCESS,
            deployment: deploymentMockData,
            showMetrics: true
          }
        });
      })

      fit('shows metrics', () => {
        console.log(wrapper.vm.showMemoryUsage);
        expect(wrapper.find(MemoryUsage).exists()).toBe(true);
      });
    });

    describe('with showMetrics disabled', () => {
      beforeEach(() => {
        factory({
          propsData: {
            computedDeploymentStatus: SUCCESS,
            deployment: deploymentMockData,
            showMetrics: false
          }
        });
      })

      fit('hides metrics', () => {
        console.log(wrapper.vm.showMemoryUsage);
        expect(wrapper.find(MemoryUsage).exists()).toBe(false);
      });
    });
  })

  // add status text and button combinations, using maybe some cool iteration protocol

});

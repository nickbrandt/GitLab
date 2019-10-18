import { shallowMount, createLocalVue } from '@vue/test-utils';
import { getTimeago } from '~/lib/utils/datetime_utility';
import DeploymentInfo from '~/vue_merge_request_widget/components/deployment_info.vue';
import MemoryUsage from '~/vue_merge_request_widget/components/memory_usage.vue';
import { MANUAL_DEPLOY, WILL_DEPLOY, RUNNING, SUCCESS, FAILED, CANCELED } from '~/vue_merge_request_widget/components/constants';
import { deploymentMockData } from './deployment_mock_data';

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

    describe('when deployment has no deployed_at', () => {
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

    describe('when deployment has no deployed_at_formatted', () => {
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

      it('shows metrics', () => {
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

      it('hides metrics', () => {
        expect(wrapper.find(MemoryUsage).exists()).toBe(false);
      });
    });
  });

  describe('status message', () => {
    describe.each`
      computedStatus   | message
      ${MANUAL_DEPLOY} | ${'Can deploy manually to'}
      ${WILL_DEPLOY}   | ${'Will deploy to'}
      ${RUNNING}       | ${'Deploying to'}
      ${SUCCESS}       | ${'Deployed to'}
      ${FAILED}        | ${'Failed to deploy to'}
      ${CANCELED}      | ${'Canceled deploy to'}
    `('$computedStatus', ({computedStatus, message}) => {
      beforeEach(() => {
          factory({
            propsData: {
              computedDeploymentStatus: computedStatus,
              deployment: deploymentMockData,
              showMetrics: false
            }
          });
        });

      it(`renders ${message}`, () => {
        expect(wrapper.find('.js-deployment-info').text()).toContain(message);
      });
    });
  });
});

import Vue from 'vue';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import DeploymentComponent from '~/vue_merge_request_widget/components/deployment.vue';
import DeploymentInfo from '~/vue_merge_request_widget/components/deployment_info.vue';
import DeploymentViewButton from '~/vue_merge_request_widget/components/deployment_view_button.vue';
import DeploymentManualButton from '~/vue_merge_request_widget/components/deployment_manual_button.vue';
import DeploymentRedeployButton from '~/vue_merge_request_widget/components/deployment_redeploy_button.vue';
import DeploymentStopButton from '~/vue_merge_request_widget/components/deployment_stop_button.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import { CREATED, MANUAL_DEPLOY, WILL_DEPLOY, RUNNING, SUCCESS, FAILED, CANCELED } from '~/vue_merge_request_widget/components/constants';


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

const manualAction = {
  "id":1139,
  "name":"deploy_manual",
  "retry_path":"/root/test-deployments/-/jobs/1139/retry",
  "play_path":"/root/test-deployments/-/jobs/1139/play",
  "playable":true,
};

describe('Deployment component', () => {

  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(DeploymentComponent), {
      localVue,
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        deployment: deploymentMockData,
        showMetrics: false
      }
    })
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('', () => {

    it('always renders DeploymentInfo', () => {
      expect(wrapper.find(DeploymentInfo).exists()).toBe(true);
    });

    fdescribe('status message and buttons', () => {
      const none = [];
      const deployGroup = [DeploymentViewButton, DeploymentStopButton];

      describe.each`
        status       | previous | manualActions     | text                        | actionButtons
        ${CREATED}   | ${true}  | ${[manualAction]} | ${'Can deploy manually to'} | ${[...deployGroup, DeploymentManualButton]}
        ${CREATED}   | ${true}  | ${none}           | ${'Will deploy to'}         | ${deployGroup}
        ${CREATED}   | ${false} | ${[manualAction]} | ${'Can deploy manually to'} | ${[DeploymentManualButton]}
        ${CREATED}   | ${false} | ${none}           | ${'Will deploy to'}         | ${none}
        ${RUNNING}   | ${true}  | ${[manualAction]} | ${'Deploying to'}           | ${deployGroup}
        ${RUNNING}   | ${true}  | ${none}           | ${'Deploying to'}           | ${deployGroup}
        ${RUNNING}   | ${false} | ${[manualAction]} | ${'Deploying to'}           | ${none}
        ${RUNNING}   | ${false} | ${none}           | ${'Deploying to'}           | ${none}
        ${SUCCESS}   | ${true}  | ${[manualAction]} | ${'Deployed to'}            | ${deployGroup}
        ${SUCCESS}   | ${true}  | ${none}           | ${'Deployed to'}            | ${deployGroup}
        ${SUCCESS}   | ${false} | ${[manualAction]} | ${'Deployed to'}            | ${deployGroup}
        ${SUCCESS}   | ${false} | ${none}           | ${'Deployed to'}            | ${deployGroup}
        ${FAILED}    | ${true}  | ${[manualAction]} | ${'Failed to deploy to'}    | ${[...deployGroup, DeploymentRedeployButton]}
        ${FAILED}    | ${true}  | ${none}           | ${'Failed to deploy to'}    | ${[...deployGroup]}
        ${FAILED}    | ${false} | ${[manualAction]} | ${'Failed to deploy to'}    | ${[DeploymentRedeployButton]}
        ${FAILED}    | ${false} | ${none}           | ${'Failed to deploy to'}    | ${[]}
        ${CANCELED}  | ${true}  | ${[manualAction]} | ${'Canceled deploy to'}     | ${deployGroup}
        ${CANCELED}  | ${true}  | ${none}           | ${'Canceled deploy to'}     | ${deployGroup}
        ${CANCELED}  | ${false} | ${[manualAction]} | ${'Canceled deploy to'}     | ${none}
        ${CANCELED}  | ${false} | ${none}           | ${'Canceled deploy to'}     | ${none}
      `('$status + previous: $previous + manual: $manualActions.length',
       ({ status, previous, manualActions, text, actionButtons }) => {
         beforeEach(() => {
           const previousOrSuccess = Boolean(previous || (status === SUCCESS));
           const updatedDeploymentData = {
             status,
             deployed_at: previous ? 'deploymentMockData.deployed_at' : null,
             deployed_at_formatted: previous ? 'deploymentMockData.deployed_at_formatted' : null,
             external_url:  previousOrSuccess ? 'deploymentMockData.external_url' : null,
             external_url_formatted:  previousOrSuccess ? 'deploymentMockData.external_url_formatted' : null,
             stop_url: previousOrSuccess ? 'deploymentMockData.stop_url' : null,
             deployment_manual_actions: manualActions
           };

           factory({
             propsData: {
               showMetrics: false,
               deployment: {
                 ...deploymentMockData,
                 ...updatedDeploymentData,
               }
             }
           });
         });

         it(`renders the text: ${text}`, () => {
           expect(wrapper.find(DeploymentInfo).text()).toContain(text);
         });

         if (actionButtons.length > 0) {
           describe('renders the expected button group', () => {
             actionButtons.forEach((button) => {
               it(`renders ${button.name}`, () => {
                 expect(wrapper.find(button).exists()).toBe(true);
               });
             });
            });
         }

         if (actionButtons.includes(DeploymentViewButton)) {
           it('renders the View button with expected text', () => {
             if (status === SUCCESS) {
               expect(wrapper.find(DeploymentViewButton).text()).toContain('View app');
             } else {
               expect(wrapper.find(DeploymentViewButton).text()).toContain('View previous app');
             }
           })
         }

         describe('does not render unexpected actionButtons', () => {
           const allButtons = [DeploymentViewButton, DeploymentStopButton, DeploymentManualButton, DeploymentRedeployButton];
           const doNotRender = allButtons.filter((button) => !actionButtons.includes(button));

           doNotRender.forEach((button) => {
             it(`does not render ${button.name}`, () => {
               expect(wrapper.find(button).exists()).toBe(false);
             })
           });
         });
       });

    });















  });

  describe('hasExternalUrls', () => {

    describe('when deployment has both external_url_formatted and external_url', () => {
      it('should return true', () => {
        expect(wrapper.vm.hasExternalUrls).toEqual(true);
      });

      it('should render the View Button', () => {
        expect(wrapper.find(DeploymentViewButton).exists()).toBe(true);
      });
    });

    describe('when deployment has no external_url_formatted', () => {
      beforeEach(() => {
        factory({
          propsData: {
            deployment: {...deploymentMockData, external_url_formatted: null },
            showMetrics: false
          }
        });
      });

      it('should return false', () => {
        expect(wrapper.vm.hasExternalUrls).toEqual(false);
      });

      it('should not render the View Button', () => {
        expect(wrapper.find(DeploymentViewButton).exists()).toBe(false);
      });
    });

    describe('when deployment has no external_url', () => {
      beforeEach(() => {
        factory({
          propsData: {
            deployment: {...deploymentMockData, external_url: null },
            showMetrics: false
          }
        });
      });

      it('should return false', () => {
        expect(wrapper.vm.hasExternalUrls).toEqual(false);
      });

      it('should not render the View Button', () => {
        expect(wrapper.find(DeploymentViewButton).exists()).toBe(false);
      });
    });
  });
});

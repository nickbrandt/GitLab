import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import job from '../mock_data';
import JobRetryForwardDeploymentModal from '~/jobs/components/job_retry_forward_deployment_modal.vue';
import { JOB_RETRY_FORWARD_DEPLOYMENT_MODAL } from '~/jobs/constants';
import createStore from '~/jobs/store';

describe('Job Retry Forward Deployment Modal', () => {
  let store;
  let wrapper;

  const findModal = () => wrapper.find(GlModal);

  const createWrapper = ({ props = {}, stubs = {} } = {}) => {
    store = createStore();
    wrapper = shallowMount(JobRetryForwardDeploymentModal, {
      propsData: {
        modalId: 'modal-id',
        href: job.retry_path,
        ...props,
      },
      store,
      stubs,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  beforeEach(createWrapper);

  describe('Modal configuration', () => {
    it('should display the correct messages', () => {
      const modal = findModal();
      expect(modal.attributes('title')).toMatch(JOB_RETRY_FORWARD_DEPLOYMENT_MODAL.title);
      expect(modal.text()).toMatch(JOB_RETRY_FORWARD_DEPLOYMENT_MODAL.body);
    });
  });

  describe('Modal actions', () => {
    beforeEach(() => {
      createWrapper({
        stubs: {
          GlModal: {
            template: `
              <div id="modal-stub"></div>
            `,
            props: {
              actionPrimary: { type: Object },
            },
          },
        },
      });
    });

    it('should correctly configure the primary action', () => {
      expect(wrapper.find('#modal-stub').props('actionPrimary').attributes).toMatchObject([
        {
          'data-method': 'post',
          href: job.retry_path,
          variant: 'danger',
        },
      ]);
    });
  });
});

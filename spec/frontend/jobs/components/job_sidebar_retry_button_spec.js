import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import job from '../mock_data';
import JobsSidebarRetryButton from '~/jobs/components/job_sidebar_retry_button.vue';
import createStore from '~/jobs/store';

describe('Job Sidebar Retry Button', () => {
  let store;
  let wrapper;

  const forwardDeploymentFailure = 'forward_deployment_failure';
  const findButton = () => wrapper.find(GlButton);

  const createWrapper = ({ props = {} } = {}) => {
    store = createStore();
    wrapper = shallowMount(JobsSidebarRetryButton, {
      propsData: {
        href: job.retry_path,
        modalId: 'modal-id',
        category: 'primary',
        ...props,
      },
      store,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  beforeEach(createWrapper);

  it.each([
    [null, job.retry_path, undefined],
    ['unmet_prerequisites', job.retry_path, undefined],
    [forwardDeploymentFailure, undefined, 'button'],
  ])(
    'when error is: %s, should render with href: %s || should render with role: %s',
    async (failureReason, href, role) => {
      await store.dispatch('receiveJobSuccess', { ...job, failure_reason: failureReason });

      expect(findButton().attributes('href')).toBe(href);
      expect(findButton().attributes('role')).toBe(role);
      expect(wrapper.text()).toMatch('Retry');
    },
  );

  describe('Button', () => {
    it('should have the correct configuration', async () => {
      await store.dispatch('receiveJobSuccess', { failure_reason: forwardDeploymentFailure });

      expect(findButton().attributes('category')).toBe('primary');
      expect(findButton().attributes('variant')).toBe('info');
    });
  });

  describe('Link', () => {
    it('should have the correct configuration', () => {
      expect(findButton().attributes('data-method')).toBe('post');
      expect(findButton().attributes('href')).toBe(job.retry_path);
    });
  });
});

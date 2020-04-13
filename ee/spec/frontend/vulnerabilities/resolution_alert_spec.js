import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import ResolutionAlert from 'ee/vulnerabilities/components/resolution_alert.vue';

describe('Vulnerability list component', () => {
  let wrapper;
  const DEFAULT_BRANCH_NAME = 'not-always-master';

  const createWrapper = (options = {}) => {
    wrapper = shallowMount(ResolutionAlert, options);
  };

  const findAlert = () => wrapper.find(GlAlert);

  afterEach(() => wrapper.destroy());

  describe('with a default branch name passed to it', () => {
    beforeEach(() => {
      createWrapper({
        propsData: { defaultBranchName: DEFAULT_BRANCH_NAME },
      });
    });

    it('should render the default branch name in the alert title', () => {
      const alert = findAlert();

      expect(alert.attributes().title).toMatch(DEFAULT_BRANCH_NAME);
    });

    it('should call the dismiss method when dismissed', () => {
      expect(wrapper.vm.isVisible).toBe(true);
      wrapper.vm.dismiss();
      expect(wrapper.vm.isVisible).toBe(false);
    });
  });

  describe('with no default branch name', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the fallback in the alert title', () => {
      const alert = findAlert();

      expect(alert.attributes().title).toMatch('in the default branch');
    });
  });
});

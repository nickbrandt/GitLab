import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import TrialStatusWidget from 'ee/contextual_sidebar/components/trial_status_widget.vue';

describe('TrialStatusWidget component', () => {
  let wrapper;

  const getGlLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props } = {}) => {
    return shallowMount(TrialStatusWidget, {
      propsData: {
        daysRemaining: 20,
        navIconImagePath: 'illustrations/golden_tanuki.svg',
        percentageComplete: 10,
        planName: 'Ultimate',
        plansHref: 'billing/path-for/group',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('without the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders without an id', () => {
      expect(getGlLink().attributes('id')).toBe(undefined);
    });

    it('renders with the correct tracking data attributes', () => {
      const attrs = getGlLink().attributes();
      expect(attrs['data-track-action']).toBe('click_link');
      expect(attrs['data-track-label']).toBe('trial_status_widget');
      expect(attrs['data-track-property']).toBe('experiment:show_trial_status_in_sidebar');
    });
  });

  describe('with the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { containerId: 'some-id' } });
    });

    it('renders with the given id', () => {
      expect(getGlLink().attributes('id')).toBe('some-id');
    });
  });
});

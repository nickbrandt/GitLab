import { shallowMount } from '@vue/test-utils';
import SeverityBadge, {
  CLASS_NAME_MAP,
} from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import { GlIcon } from '@gitlab/ui';

describe('Severity Badge', () => {
  let wrapper;

  const factory = (propsData = {}) =>
    shallowMount(SeverityBadge, {
      propsData: { ...propsData },
    });

  describe.each(Object.keys(CLASS_NAME_MAP))('given a valid severity %s', severity => {
    const className = CLASS_NAME_MAP[severity];

    it(`renders the component with ${severity} badge`, () => {
      wrapper = factory({ severity });

      expect(wrapper.find(`.${className}`).exists()).toBe(true);
    });

    it('renders gl-icon with correct name', () => {
      wrapper = factory({ severity });
      const icon = wrapper.find(GlIcon);
      expect(icon.props('name')).toBe(`severity-${severity}`);
    });

    it(`renders the component label`, () => {
      wrapper = factory({ severity });

      expect(wrapper.text()).toMatch(new RegExp(severity, 'i'));
    });
  });

  describe.each(['foo', '', ' '])('given an invalid severity "%s"', invalidSeverity => {
    it(`renders an empty component`, () => {
      wrapper = factory({ severity: invalidSeverity });

      expect(wrapper.isEmpty()).toBe(true);
    });
  });
});

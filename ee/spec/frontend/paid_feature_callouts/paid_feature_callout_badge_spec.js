import { GlBadge, GlIcon } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { shallowMount } from '@vue/test-utils';

import PaidFeatureCalloutBadge from 'ee/paid_feature_callouts/components/paid_feature_callout_badge.vue';
import { mockTracking } from 'helpers/tracking_helper';

describe('PaidFeatureCalloutBadge component', () => {
  let trackingSpy;
  let wrapper;

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findGlIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = () => {
    return shallowMount(PaidFeatureCalloutBadge);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with some default props', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('sets attributes on the GlBadge component', () => {
      expect(findGlBadge().attributes()).toMatchObject({
        title: 'This feature is part of your GitLab Ultimate trial.',
        tabindex: '0',
        size: 'sm',
        class: 'feature-highlight-badge',
      });
    });

    it('sets attributes on the GlIcon component', () => {
      expect(findGlIcon().attributes()).toEqual({
        name: 'license',
        size: '14',
      });
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      wrapper = createComponent();
    });

    it('tracks that the badge has been displayed when mounted', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'display_badge', {
        label: 'feature_highlight_badge',
        property: 'experiment:highlight_paid_features_during_active_trial',
      });
    });
  });

  describe('onResize', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it.each`
      bp      | tooltipDisabled
      ${'xs'} | ${false}
      ${'sm'} | ${true}
      ${'md'} | ${true}
      ${'lg'} | ${true}
      ${'xl'} | ${true}
    `(
      'sets tooltipDisabled to `$tooltipDisabled` when the breakpoint is "$bp"',
      async ({ bp, tooltipDisabled }) => {
        jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue(bp);

        wrapper.vm.onResize();
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.tooltipDisabled).toBe(tooltipDisabled);
      },
    );
  });
});

import { GlPopover } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { shallowMount } from '@vue/test-utils';

import PaidFeatureCalloutPopover from 'ee/paid_feature_callouts/components/paid_feature_callout_popover.vue';
import { mockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('PaidFeatureCalloutPopover', () => {
  let trackingSpy;
  let wrapper;

  const findGlPopover = () => wrapper.findComponent(GlPopover);

  const defaultProps = {
    daysRemaining: 12,
    featureName: 'some feature',
    hrefComparePlans: '/group/test-group/-/billings',
    hrefUpgradeToPaid: '/-/subscriptions/new?namespace_id=123&plan_id=abc456',
    planNameForTrial: 'Awesomesauce',
    planNameForUpgrade: 'Amazing',
    targetId: 'some-feature-callout-target',
  };

  const createComponent = (props = defaultProps) => {
    return extendedWrapper(
      shallowMount(PaidFeatureCalloutPopover, {
        propsData: props,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('GlPopover attributes', () => {
    describe('with some default props', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('sets attributes on the GlPopover component', () => {
        const attributes = findGlPopover().attributes();

        expect(attributes).toMatchObject({
          boundary: 'viewport',
          placement: 'top',
          target: 'some-feature-callout-target',
        });
        expect(attributes.containerId).toBeUndefined();
      });
    });

    describe('with additional, optional props', () => {
      beforeEach(() => {
        wrapper = createComponent({
          ...defaultProps,
          containerId: 'some-container-id',
        });
      });

      it('sets more attributes on the GlPopover component', () => {
        expect(findGlPopover().attributes()).toMatchObject({
          boundary: 'viewport',
          container: 'some-container-id',
          placement: 'top',
          target: 'some-feature-callout-target',
        });
      });
    });
  });

  describe('popoverTitle', () => {
    it('renders the title text', () => {
      wrapper = createComponent();

      expect(wrapper.vm.popoverTitle).toEqual('12 days remaining to enjoy some feature');
    });
  });

  describe('popoverContent', () => {
    it('renders the content text', () => {
      wrapper = createComponent();

      expect(wrapper.vm.popoverContent).toEqual(
        'Enjoying your GitLab Awesomesauce trial? To continue using some feature after your trial ends, upgrade to ' +
          'GitLab Amazing.',
      );
    });
  });

  describe('promo image', () => {
    const findPromoImage = () => wrapper.findByTestId('promo-img');

    describe('with the optional promoImagePath prop', () => {
      beforeEach(() => {
        wrapper = createComponent({
          ...defaultProps,
          promoImagePath: 'path/to/some/image.svg',
        });
      });

      it('renders the promo image', () => {
        expect(findPromoImage().exists()).toBe(true);
      });

      describe('with the optional promoImageAltText prop', () => {
        beforeEach(() => {
          wrapper = createComponent({
            ...defaultProps,
            promoImagePath: 'path/to/some/image.svg',
            promoImageAltText: 'My fancy alt text',
          });
        });

        it('renders the promo image with the given alt text', () => {
          expect(findPromoImage().attributes('alt')).toBe('My fancy alt text');
        });
      });

      describe('without the optional promoImageAltText prop', () => {
        beforeEach(() => {
          wrapper = createComponent({
            ...defaultProps,
            promoImagePath: 'path/to/some/image.svg',
          });
        });

        it('renders the promo image with default alt text', () => {
          expect(findPromoImage().attributes('alt')).toBe('SVG illustration');
        });
      });
    });

    describe('without the optional promoImagePath prop', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('does not render a promo image', () => {
        expect(findPromoImage().exists()).toBe(false);
      });
    });
  });

  describe('call-to-action buttons', () => {
    const findUpgradeBtn = () => wrapper.findByTestId('upgradeBtn');
    const findCompareBtn = () => wrapper.findByTestId('compareBtn');

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('correctly renders an Upgrade button', () => {
      const upgradeBtn = findUpgradeBtn();

      expect(upgradeBtn.text()).toEqual('Upgrade to GitLab Amazing');
      expect(upgradeBtn.attributes()).toMatchObject({
        href: '/-/subscriptions/new?namespace_id=123&plan_id=abc456',
        target: '_blank',
        category: 'primary',
        variant: 'confirm',
        size: 'small',
        block: '',
        'data-track-action': 'click_button',
        'data-track-label': 'upgrade_to_ultimate',
        'data-track-property': 'experiment:highlight_paid_features_during_active_trial',
      });
    });

    it('correctly renders a Compare button', () => {
      const compareBtn = findCompareBtn();

      expect(compareBtn.text()).toEqual('Compare all plans');
      expect(compareBtn.attributes()).toMatchObject({
        href: '/group/test-group/-/billings',
        target: '_blank',
        category: 'secondary',
        variant: 'confirm',
        size: 'small',
        block: '',
        'data-track-action': 'click_button',
        'data-track-label': 'compare_all_plans',
        'data-track-property': 'experiment:highlight_paid_features_during_active_trial',
      });
    });
  });

  describe('onShown', () => {
    beforeEach(() => {
      trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      wrapper = createComponent();
      findGlPopover().vm.$emit('shown');
    });

    it('tracks that the popover has been shown', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'popover_shown', {
        label: 'feature_highlight_popover:some feature',
        property: 'experiment:highlight_paid_features_during_active_trial',
      });
    });
  });

  describe('onResize', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it.each`
      bp      | disabled
      ${'xs'} | ${'true'}
      ${'sm'} | ${undefined}
      ${'md'} | ${undefined}
      ${'lg'} | ${undefined}
      ${'xl'} | ${undefined}
    `(
      'sets the GlPopover’s disabled attribute to `$disabled` when the breakpoint is "$bp"',
      async ({ bp, disabled }) => {
        jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue(bp);

        wrapper.vm.onResize();
        await wrapper.vm.$nextTick();

        expect(findGlPopover().attributes('disabled')).toBe(disabled);
      },
    );
  });
});

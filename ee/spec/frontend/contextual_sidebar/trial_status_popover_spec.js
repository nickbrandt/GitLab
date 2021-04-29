import { GlPopover } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { shallowMount } from '@vue/test-utils';

import TrialStatusPopover from 'ee/contextual_sidebar/components/trial_status_popover.vue';
import { mockTracking } from 'helpers/tracking_helper';
import axios from '~/lib/utils/axios_utils';

describe('TrialStatusPopover component', () => {
  let wrapper;
  let trackingSpy;

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findGlPopover = () => wrapper.findComponent(GlPopover);

  const defaultProviders = {
    groupName: 'Some Test Group',
    planName: 'Ultimate',
    plansHref: 'billing/path-for/group',
    purchaseHref: 'transactions/new',
    trialEndDate: new Date('2021-02-28'),
  };

  const defaultProps = {
    targetId: 'target-element-identifier',
  };

  const createComponent = ({ provide = {}, propsData = {}, ...options } = {}) => {
    return shallowMount(TrialStatusPopover, {
      provide: {
        ...defaultProviders,
        ...provide,
      },
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      ...options,
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('call-to-action buttons', () => {
    const sharedAttrs = {
      variant: 'confirm',
      size: 'small',
      block: '',
    };

    describe('the Upgrade button', () => {
      it('renders correctly', () => {
        const upgradeBtn = findByTestId('upgradeBtn');

        expect(upgradeBtn.text()).toEqual('Upgrade Some Test Group to Ultimate');
        expect(upgradeBtn.attributes()).toMatchObject({
          ...sharedAttrs,
          href: 'transactions/new',
          category: 'primary',
        });
      });

      it('tracks clicks', () => {
        findByTestId('upgradeBtn').vm.$emit('click');

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'click_button',
          expect.objectContaining({
            label: 'upgrade_to_ultimate',
            property: 'experiment:show_trial_status_in_sidebar',
          }),
        );
      });
    });

    describe('the Compare Plans button', () => {
      it('renders correctly', () => {
        const compareBtn = findByTestId('compareBtn');

        expect(compareBtn.text()).toEqual('Compare all plans');
        expect(compareBtn.attributes()).toMatchObject({
          ...sharedAttrs,
          href: 'billing/path-for/group',
          category: 'secondary',
        });
      });

      it('tracks clicks', () => {
        findByTestId('compareBtn').vm.$emit('click');

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'click_button',
          expect.objectContaining({
            label: 'compare_all_plans',
            property: 'experiment:show_trial_status_in_sidebar',
          }),
        );
      });
    });
  });

  describe('startInitiallyShown', () => {
    describe('when set to true', () => {
      beforeEach(() => {
        wrapper = createComponent({ provide: { startInitiallyShown: true } });
      });

      it('causes the popover to be shown by default', () => {
        expect(findGlPopover().attributes('show')).toBeTruthy();
      });

      it('removes the popover triggers', () => {
        expect(findGlPopover().attributes('triggers')).toBe('');
      });
    });

    describe('when set to false', () => {
      beforeEach(() => {
        wrapper = createComponent({ provide: { startInitiallyShown: false } });
      });

      it('does not cause the popover to be shown by default', () => {
        expect(findGlPopover().attributes('show')).toBeFalsy();
      });

      it('uses the standard triggers for the popover', () => {
        expect(findGlPopover().attributes('triggers')).toBe('hover focus');
      });
    });
  });

  describe('methods', () => {
    describe('onForciblyShown', () => {
      beforeEach(() => {
        jest.spyOn(axios, 'post').mockReturnValue(Promise.resolve('success'));
      });

      describe('when userCalloutsPath and userCalloutsFeatureId are set', () => {
        const userCalloutProps = {
          userCalloutsPath: 'user_callouts/path',
          userCalloutsFeatureId: 'feature_id',
        };

        beforeEach(() => {
          wrapper = createComponent({ provide: userCalloutProps });
          wrapper.vm.onForciblyShown();
        });

        it('sends a request to update the specified UserCallout record', () => {
          expect(axios.post).toHaveBeenCalledWith(userCalloutProps.userCalloutsPath, {
            feature_name: userCalloutProps.userCalloutsFeatureId,
          });
        });
      });

      describe.each`
        path                    | featureId
        ${'user_callouts/path'} | ${undefined}
        ${undefined}            | ${'feature_id'}
        ${undefined}            | ${undefined}
      `(
        'when userCalloutsPath is `$path` and userCalloutsFeatureId is `$featureId`',
        ({ path, featureId }) => {
          beforeEach(() => {
            wrapper = createComponent({
              provide: { userCalloutsPath: path, userCalloutsFeatureId: featureId },
            });
            wrapper.vm.onForciblyShown();
          });

          it('does not send a request', () => {
            expect(axios.post).not.toHaveBeenCalled();
          });
        },
      );
    });

    describe('onClose', () => {
      beforeEach(() => {
        jest.spyOn(findGlPopover().vm, '$emit');
        wrapper.vm.onClose();
      });

      it('tells the popover component to close', () => {
        expect(findGlPopover().vm.$emit).toHaveBeenCalledWith('close');
      });

      it('sets forciblyShowing to false', () => {
        expect(wrapper.vm.forciblyShowing).toBeFalsy();
      });

      it('tracks an event', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
          label: 'close_popover',
          property: 'experiment:show_trial_status_in_sidebar',
        });
      });
    });

    describe('onResize', () => {
      it.each`
        bp      | isDisabled
        ${'xs'} | ${'true'}
        ${'sm'} | ${'true'}
        ${'md'} | ${undefined}
        ${'lg'} | ${undefined}
        ${'xl'} | ${undefined}
      `(
        'sets disabled to `$isDisabled` when the breakpoint is "$bp"',
        async ({ bp, isDisabled }) => {
          jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue(bp);

          wrapper.vm.onResize();
          await wrapper.vm.$nextTick();

          expect(findGlPopover().attributes('disabled')).toBe(isDisabled);
        },
      );
    });

    describe('onShown', () => {
      beforeEach(() => {
        findGlPopover().vm.$emit('shown');
      });

      it('dispatches tracking event', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'popover_shown', {
          label: 'trial_status_popover',
          property: 'experiment:show_trial_status_in_sidebar',
        });
      });
    });
  });
});

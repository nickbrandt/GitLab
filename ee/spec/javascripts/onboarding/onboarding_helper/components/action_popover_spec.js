import component from 'ee/onboarding/onboarding_helper/components/action_popover.vue';
import { shallowMount } from '@vue/test-utils';
import eventHub from 'ee/onboarding/onboarding_helper/event_hub';

describe('User onboarding action popover', () => {
  let wrapper;
  let props;

  const target = document.createElement('a');
  const content = 'This is some test content';
  const placement = 'top';
  const showDefault = true;

  beforeEach(() => {
    props = {
      target,
      content,
      placement,
      showDefault,
    };
    wrapper = shallowMount(component, {
      propsData: props,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('mounted', () => {
    it("binds 'onboardingHelper.showActionPopover', 'onboardingHelper.hideActionPopover' and 'onboardingHelper.destroyActionPopover' event listener on eventHub", () => {
      spyOn(eventHub, '$on');

      const wrapperX = shallowMount(component, {
        propsData: props,
      });

      expect(eventHub.$on).toHaveBeenCalledWith(
        'onboardingHelper.showActionPopover',
        jasmine.any(Function),
      );

      expect(eventHub.$on).toHaveBeenCalledWith(
        'onboardingHelper.hideActionPopover',
        jasmine.any(Function),
      );

      expect(eventHub.$on).toHaveBeenCalledWith(
        'onboardingHelper.destroyActionPopover',
        jasmine.any(Function),
      );

      wrapperX.destroy();
    });
  });

  describe('beforeDestroy', () => {
    it("unbinds 'showActionPopover', 'hideActionPopover' and 'destroyActionPopover' event handler", () => {
      spyOn(eventHub, '$off');

      wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith('onboardingHelper.showActionPopover');
      expect(eventHub.$off).toHaveBeenCalledWith('onboardingHelper.hideActionPopover');
      expect(eventHub.$off).toHaveBeenCalledWith('onboardingHelper.destroyActionPopover');
    });
  });

  describe('methods', () => {
    describe('toggleShowPopover', () => {
      it('updates the showPopover property', () => {
        wrapper.vm.showPopover = false;

        wrapper.vm.toggleShowPopover(true);

        expect(wrapper.vm.showPopover).toBeTruthy();
      });
    });
  });

  describe('template', () => {
    it('shows the content passed in as prop', () => {
      expect(wrapper.text()).toEqual(content);
    });
  });
});

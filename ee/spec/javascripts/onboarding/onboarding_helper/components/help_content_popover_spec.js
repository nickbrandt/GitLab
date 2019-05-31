import component from 'ee/onboarding/onboarding_helper/components/help_content_popover.vue';
import { shallowMount } from '@vue/test-utils';

describe('User onboarding help content popover', () => {
  let wrapper;

  const target = document.createElement('a');
  const helpContent = {
    text: 'some help content',
    buttons: [{ text: 'button', btnClass: 'btn-primary' }],
  };

  const defaultProps = {
    target,
    helpContent,
    placement: 'top',
    show: false,
    disabled: false,
  };

  function createComponent(propsData) {
    wrapper = shallowMount(component, { propsData });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('callButtonAction', () => {
      it('emits clickActionButton when called', () => {
        createComponent(defaultProps);

        wrapper.find('.btn-primary').vm.$emit('click');

        expect(wrapper.emittedByOrder()).toEqual([
          { name: 'clickActionButton', args: [defaultProps.helpContent.buttons[0]] },
        ]);
      });
    });
  });

  describe('template', () => {
    it('displays the help content text and renders a primary button with the text "button"', () => {
      createComponent(defaultProps);

      const btn = wrapper.find('.btn-primary');

      expect(wrapper.text()).toContain(defaultProps.helpContent.text);
      expect(btn.exists()).toBe(true);
      expect(btn.text()).toBe(defaultProps.helpContent.buttons[0].text);
    });

    it('renders a secondary button with the text "button"', () => {
      const propsData = {
        ...defaultProps,
        helpContent: {
          ...defaultProps.helpContent,
          buttons: [{ text: 'button', btnClass: 'btn-secondary' }],
        },
      };
      createComponent(propsData);

      const btn = wrapper.find('.btn-secondary');

      expect(btn.exists()).toBe(true);
      expect(btn.text()).toBe(propsData.helpContent.buttons[0].text);
    });

    it("does not render any buttons if the help content doesn't contain buttons", () => {
      const propsData = {
        ...defaultProps,
        helpContent: {
          ...defaultProps.helpContent,
          buttons: null,
        },
      };
      createComponent(propsData);

      const primaryBtn = wrapper.find('.btn-primary');
      const secondaryBtn = wrapper.find('.btn-secondary');

      expect(primaryBtn.exists()).toBe(false);
      expect(secondaryBtn.exists()).toBe(false);
    });

    it('updates the help content text when props change', () => {
      const propsData = {
        ...defaultProps,
        helpContent: {
          ...defaultProps.helpContent,
          text: 'updated text',
        },
      };
      createComponent(propsData);

      expect(wrapper.text()).toContain(propsData.helpContent.text);
    });
  });
});

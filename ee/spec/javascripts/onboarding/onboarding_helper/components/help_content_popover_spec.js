import component from 'ee/onboarding/onboarding_helper/components/help_content_popover.vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

const localVue = createLocalVue();

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

  const exitTourContent = {
    text: 'some help content',
    buttonText: "Close 'Learn GitLab'",
    exitTour: true,
  };

  const exitTourProps = {
    ...defaultProps,
    helpContent: exitTourContent,
  };

  const feedbackContent = {
    text: 'some help content',
    feedbackButtons: true,
    feedbackSize: 5,
  };

  const feedbackProps = {
    ...defaultProps,
    helpContent: feedbackContent,
  };

  function createComponent(propsData) {
    wrapper = shallowMount(localVue.extend(component), { propsData, localVue, sync: false });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('callStepContentButton', () => {
      it('emits clickStepContentButton when called', () => {
        createComponent(defaultProps);

        wrapper.find('.btn-primary').vm.$emit('click');

        expect(wrapper.emittedByOrder()).toEqual([
          { name: 'clickStepContentButton', args: [defaultProps.helpContent.buttons[0]] },
        ]);
      });
    });

    describe('callExitTour', () => {
      it('emits clickExitTourButton when called', () => {
        createComponent(exitTourProps);

        wrapper.find(GlButton).vm.$emit('click');

        expect(wrapper.emittedByOrder()).toEqual([{ name: 'clickExitTourButton', args: [] }]);
      });
    });

    describe('submitFeedback', () => {
      it('emits clickFeedbackButton when called', () => {
        createComponent(feedbackProps);

        wrapper.find(GlButton).vm.$emit('click');

        expect(wrapper.emittedByOrder()).toEqual([
          { name: 'clickFeedbackButton', args: [{ feedbackResult: 1 }] },
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

    it('displays the help content text and renders a primary button with exit text when there is no buttons in help content', () => {
      createComponent(exitTourProps);

      const btn = wrapper.find('.btn-primary');

      expect(wrapper.text()).toContain(exitTourProps.helpContent.text);
      expect(btn.exists()).toBe(true);
      expect(btn.text()).toBe("Close 'Learn GitLab'");
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

import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlProgressBar, GlLoadingIcon } from '@gitlab/ui';
import component from 'ee/onboarding/onboarding_helper/components/onboarding_helper.vue';
import TourPartsList from 'ee/onboarding/onboarding_helper/components/tour_parts_list.vue';
import Icon from '~/vue_shared/components/icon.vue';
import Tracking from '~/tracking';

const localVue = createLocalVue();

describe('User onboarding tour parts list', () => {
  let wrapper;

  const defaultProps = {
    tourTitles: [
      { id: 1, title: 'First tour' },
      { id: 2, title: 'Second tour' },
      { id: 3, title: 'Yet another tour' },
    ],
    activeTour: 1,
    totalStepsForTour: 10,
    helpContent: {
      text: 'help content popover text',
      buttons: [{ text: 'OK', btnClass: 'btn-primary' }],
    },
    percentageCompleted: 50,
    completedSteps: 3,
    initialShow: false,
    dismissPopover: false,
    goldenTanukiSvgPath: 'illustrations/golden_tanuki.svg',
    showLoadingIcon: false,
  };

  function createComponent(propsData) {
    wrapper = shallowMount(localVue.extend(component), {
      propsData,
      localVue,
    });
  }

  beforeEach(() => {
    createComponent(defaultProps);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('totalTours', () => {
      it('returns the total number of tours', () => {
        expect(wrapper.vm.totalTours).toBe(defaultProps.tourTitles.length);
      });
    });

    describe('tourInfo', () => {
      it('returns "1/3"', () => {
        expect(wrapper.vm.tourInfo).toEqual('1/3');
      });
    });

    describe('toggleButtonLabel', () => {
      it('returns "More" if the helper is collapsed', () => {
        expect(wrapper.vm.toggleButtonLabel).toEqual('More');
      });

      it('returns "Close" if the helper is expanded', () => {
        wrapper.vm.expanded = true;

        expect(wrapper.vm.toggleButtonLabel).toEqual('Close');
      });
    });

    describe('toggleButtonIcon', () => {
      it('returns "ellipsis_h" if the helper is collapsed', () => {
        expect(wrapper.vm.toggleButtonIcon).toEqual('ellipsis_h');
      });

      it('returns "close" if the helper is expanded', () => {
        wrapper.vm.expanded = true;

        expect(wrapper.vm.toggleButtonIcon).toEqual('close');
      });
    });

    describe('showLink', () => {
      it('returns true per default', () => {
        expect(wrapper.vm.showLink).toBe(true);
      });

      it('returns false if the activeTour is null', () => {
        const props = {
          ...defaultProps,
          activeTour: null,
        };

        createComponent(props);

        expect(wrapper.vm.showLink).toBeFalsy();
      });

      it('returns false if the helpContent is null', () => {
        const props = {
          ...defaultProps,
          helpContent: null,
        };

        createComponent(props);

        expect(wrapper.vm.showLink).toBeFalsy();
      });

      it('returns false if the helpContent is undefined', () => {
        const props = {
          ...defaultProps,
          helpContent: undefined,
        };

        createComponent(props);

        expect(wrapper.vm.showLink).toBeFalsy();
      });
    });
  });

  describe('mounted', () => {
    it('sets the helpContentTrigger', () => {
      expect(wrapper.vm.helpContentTrigger).not.toBe(null);
    });
  });

  describe('watch', () => {
    describe('watch initialShow', () => {
      it('sets showPopover to true if initialShow is true', done => {
        wrapper.setProps({ initialShow: true });

        wrapper.vm
          .$nextTick()
          .then(() => {
            expect(wrapper.vm.showPopover).toBe(true);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('watch dismissPopover', () => {
      it('sets popoverDismissed to true and showPopover to false if dismissPopover is true', done => {
        wrapper.setProps({ dismissPopover: true });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.showPopover).toBe(false);
          expect(wrapper.vm.popoverDismissed).toBe(true);

          done();
        });
      });

      it('sets popoverDismissed to false dismissPopover is false', done => {
        wrapper.setProps({ dismissPopover: false });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.popoverDismissed).toBe(false);

          done();
        });
      });
    });
  });

  describe('methods', () => {
    describe('transitionEndCallback', () => {
      it('sets showPopover to true if popoverDismissed and expanded are false', () => {
        wrapper.vm.popoverDismissed = false;
        wrapper.vm.expanded = false;
        wrapper.vm.showPopover = false;

        wrapper.vm.transitionEndCallback();

        expect(wrapper.vm.showPopover).toBe(true);
      });
    });

    describe('toggleMenu', () => {
      it('expands and collapses the menu correctly', () => {
        wrapper.vm.expanded = false;

        wrapper.vm.toggleMenu();

        expect(wrapper.vm.expanded).toBe(true);

        wrapper.vm.expanded = true;

        wrapper.vm.toggleMenu();

        expect(wrapper.vm.expanded).toBe(false);
      });

      it('hides the popover if currently expanded and popoverDismissed is false', () => {
        wrapper.vm.expanded = true;
        wrapper.vm.popoverDismissed = false;

        wrapper.vm.toggleMenu();

        expect(wrapper.vm.showPopover).toBe(false);
      });
    });

    describe('skipStep', () => {
      it('emits the "skipStep" event when the "Skip this step" link is clicked', () => {
        wrapper.find('.qa-skip-step-link').vm.$emit('click');

        expect(wrapper.emitted('skipStep')).toBeTruthy();
      });

      it('displays the loading icon instead of the tanuki SVG when the "Skip this step" link is clicked', done => {
        wrapper.find('.qa-skip-step-link').vm.$emit('click');

        expect(wrapper.vm.showLoadingIcon).toBe(true);

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
          expect(wrapper.find('.avatar img').exists()).toBe(false);

          done();
        });
      });
    });

    describe('restartStep', () => {
      it('emits the "restartStep" event when the "Restart this step" link is clicked', () => {
        wrapper.find('.qa-restart-step-link').vm.$emit('click');

        expect(wrapper.emitted('restartStep')).toBeTruthy();
      });
    });

    describe('beginExitTourProcess', () => {
      const findExitTourLink = () => wrapper.find('.qa-exit-tour-link');

      it('emits the "showDntExitContent" event when the "Exit Learn GitLab" link is clicked and tracking is not enabled', () => {
        spyOn(Tracking, 'enabled').and.returnValue(false);

        findExitTourLink().vm.$emit('click');

        expect(wrapper.emitted('showDntExitContent')).toBeTruthy();
        expect(Tracking.enabled).toHaveBeenCalled();
      });

      it('emits the "showFeedbackContent" event when the "Exit Learn GitLab" link is clicked and tracking is enabled', () => {
        spyOn(Tracking, 'enabled').and.returnValue(true);

        findExitTourLink().vm.$emit('click');

        expect(wrapper.emitted('showFeedbackContent')).toBeTruthy();
      });
    });

    describe('callStepContentButton', () => {
      it('emits the "clickStepContentButton" event when a popover button is clicked', () => {
        const button = defaultProps.helpContent.buttons[0];

        wrapper.vm.callStepContentButton(button);

        expect(wrapper.emittedByOrder()).toEqual([
          { name: 'clickStepContentButton', args: [button] },
        ]);
      });
    });

    describe('callExitTour', () => {
      it('emits the "clickExitTourButton" event when close Learn GitLab is clicked', () => {
        wrapper.vm.callExitTour();

        expect(wrapper.emittedByOrder()).toEqual([{ name: 'clickExitTourButton', args: [] }]);
      });
    });

    describe('submitFeedback', () => {
      it('emits the "clickFeedbackButton" event when feedback on tour is clicked', () => {
        const button = defaultProps.helpContent.buttons[0];

        wrapper.vm.submitFeedback(button);

        expect(wrapper.emittedByOrder()).toEqual([{ name: 'clickFeedbackButton', args: [button] }]);
      });
    });
  });

  describe('template', () => {
    it('it adds the "expanded" class to the container if expanded is true', done => {
      wrapper.vm.expanded = true;

      wrapper.vm.$nextTick(() => {
        expect(wrapper.classes('expanded')).toEqual(true);

        done();
      });
    });

    it('renders the tanuki illustration', () => {
      const img = wrapper.find('.avatar img');

      expect(img.exists()).toBe(true);
      expect(img.attributes('src')).toEqual(defaultProps.goldenTanukiSvgPath);
    });

    it('renders the headline', () => {
      const headline = wrapper.find('.qa-headline');
      const title = headline.find('.title');

      expect(headline.exists()).toBe(true);
      expect(title.text()).toBe('Learn GitLab');
      expect(headline.text()).toContain('1/3');
    });

    it('renders the progress bar with the correct value', () => {
      const progressBar = wrapper.find(GlProgressBar);

      expect(progressBar.exists()).toBe(true);

      expect(progressBar.attributes('value')).toEqual(`${defaultProps.percentageCompleted}`);
    });

    it('renders the toggle button', () => {
      expect(wrapper.find('.qa-toggle-btn').exists()).toBe(true);
    });

    it('renders the proper toggle button icons', done => {
      const btn = wrapper.find('.qa-toggle-btn');
      const icon = btn.find(Icon);

      expect(icon.props('name')).toEqual('ellipsis_h');

      wrapper.vm.expanded = true;

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(icon.props('name')).toEqual('close');
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders the tour parts list if there are tour titles', () => {
      const { tourTitles, activeTour, totalStepsForTour, completedSteps } = defaultProps;

      expect(wrapper.find(TourPartsList).exists()).toBe(true);

      expect(wrapper.find(TourPartsList).props()).toEqual(
        jasmine.objectContaining({
          tourTitles,
          activeTour,
          totalStepsForTour,
          completedSteps,
        }),
      );
    });

    it("does not render the tour parts list if there aren't tour titles", () => {
      const props = {
        ...defaultProps,
        tourTitles: [],
      };
      createComponent(props);

      expect(wrapper.find(TourPartsList).exists()).toBe(false);
    });

    it('renders "Skip this step", "Restart this step" and "Exit Learn GitLab" links', () => {
      expect(wrapper.find('.qa-skip-step-link').exists()).toBe(true);
      expect(wrapper.find('.qa-restart-step-link').exists()).toBe(true);
    });

    it('does not render the "Skip this step" and "Restart this step" links if showLink is false', () => {
      const props = {
        ...defaultProps,
        activeTour: null,
      };
      createComponent(props);

      expect(wrapper.find('.qa-skip-step-link').exists()).toBe(false);
      expect(wrapper.find('.qa-skip-step-link').exists()).toBe(false);
    });
  });
});

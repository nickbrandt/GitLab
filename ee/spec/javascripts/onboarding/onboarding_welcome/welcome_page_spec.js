import Vue from 'vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import component from 'ee/onboarding/onboarding_welcome/components/welcome_page.vue';
import ActionPopover from 'ee/onboarding/onboarding_helper/components/action_popover.vue';
import HelpContentPopover from 'ee/onboarding/onboarding_helper/components/help_content_popover.vue';
import onboardingUtils from 'ee/onboarding/utils';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

const localVue = createLocalVue();

describe('User onboarding welcome page', () => {
  let wrapper;
  const props = {
    userAvatarUrl: 'my-user.avatar.com',
    projectFullPath: 'my-dummy-project/path',
    skipUrl: 'skip.url.com',
    fromHelpMenu: false,
  };

  function createComponent(propsData) {
    wrapper = shallowMount(localVue.extend(component), {
      propsData,
      localVue,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(done => {
    createComponent(props);
    Vue.nextTick(done);
  });

  const findSkipBtn = () => wrapper.find('.qa-skip-tour-btn');

  describe('methods', () => {
    describe('startTour', () => {
      it('resets the localStorage', done => {
        spyOnDependency(component, 'redirectTo');
        spyOn(onboardingUtils, 'resetOnboardingLocalStorage').and.stub();

        wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.startTour())
          .then(wrapper.vm.$nextTick)
          .then(() => {
            expect(onboardingUtils.resetOnboardingLocalStorage).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('sets the dismissed property to false', done => {
        spyOnDependency(component, 'redirectTo');
        spyOn(onboardingUtils, 'updateOnboardingDismissed').and.stub();

        wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.startTour())
          .then(wrapper.vm.$nextTick)
          .then(() => {
            expect(onboardingUtils.updateOnboardingDismissed).toHaveBeenCalledWith(false);
          })
          .then(done)
          .catch(done.fail);
      });

      it('redirects to the project path', done => {
        const redirectSpy = spyOnDependency(component, 'redirectTo');
        wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.startTour())
          .then(wrapper.vm.$nextTick)
          .then(() => {
            expect(redirectSpy).toHaveBeenCalledWith(props.projectFullPath);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('skipTour', () => {
      it('sets the dismissed property to true', done => {
        spyOnDependency(component, 'redirectTo');
        spyOn(onboardingUtils, 'updateOnboardingDismissed').and.stub();

        wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.skipTour())
          .then(wrapper.vm.$nextTick)
          .then(() => {
            expect(onboardingUtils.updateOnboardingDismissed).toHaveBeenCalledWith(true);
          })
          .then(done)
          .catch(done.fail);
      });

      it('redirects to the skip url', done => {
        const redirectSpy = spyOnDependency(component, 'redirectTo');
        wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.skipTour())
          .then(wrapper.vm.$nextTick)
          .then(() => {
            expect(redirectSpy).toHaveBeenCalledWith(props.skipUrl);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('template', () => {
    it('renders the user avatar', () => {
      const userAvatarImage = wrapper.find(UserAvatarImage);

      expect(userAvatarImage.exists()).toBe(true);
      expect(userAvatarImage.props('imgSrc')).toEqual(props.userAvatarUrl);
    });

    it('displays the title', () => {
      expect(wrapper.text()).toContain('Hello there');
    });

    it('displays the subtitle', () => {
      expect(wrapper.text()).toContain('Welcome to the Guided GitLab Tour');
    });

    it('displays the welcome text', () => {
      expect(wrapper.text()).toContain(
        'We created a short guided tour that will help you learn the basics of GitLab and how it will help you be better at your job. It should only take a couple of minutes. You will be guided by two types of helpers, best recognized by their color.',
      );
    });

    it('displays the help content popover', () => {
      const helpContentPopover = wrapper.find(HelpContentPopover);

      expect(helpContentPopover.exists()).toBe(true);
      expect(helpContentPopover.props('helpContent').text).toEqual(
        'White helpers give contextual information.',
      );
    });

    it('displays the action popover', () => {
      const actionPopover = wrapper.find(ActionPopover);

      expect(actionPopover.exists()).toBe(true);
      expect(actionPopover.props('content')).toEqual(
        'Blue helpers indicate an action to be taken.',
      );
    });

    it('displays the "Ok let\'s got" button', () => {
      const btn = wrapper.find('.qa-start-tour-btn');

      expect(btn.exists()).toBe(true);
      expect(btn.text()).toContain("Ok let's go");
    });

    it('displays "Skip this for now" as link text if fromHelpMenu is false', () => {
      expect(findSkipBtn().exists()).toBe(true);
      expect(findSkipBtn().text()).toContain('Skip this for now');
    });

    it('displays "No, not interested right now" as link text if fromHelpMenu is true', () => {
      const propsData = {
        ...props,
        fromHelpMenu: true,
      };

      createComponent(propsData);

      expect(findSkipBtn().exists()).toBe(true);
      expect(findSkipBtn().text()).toContain('No, not interested right now');
    });

    it('displays a note on how users can start the tour from the help menu', () => {
      expect(wrapper.text()).toContain(
        "Don't worry, you can access this tour by clicking on the help icon in the top right corner and choose Learn GitLab.",
      );
    });
  });
});

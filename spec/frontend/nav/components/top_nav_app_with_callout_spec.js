import { GlPopover } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import TopNavApp from '~/nav/components/top_nav_app.vue';
import TopNavAppWithCallout from '~/nav/components/top_nav_app_with_callout.vue';
import { setSeenTopNav } from '~/nav/utils/has_seen_top_nav';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { TEST_NAV_DATA } from '../mock_data';

jest.mock('~/nav/utils/has_seen_top_nav');

const cleanSprintfPlaceholders = (str) => str.replace(/%\{.+?\}/g, '');

describe('~/nav/components/top_nav_app_with_callout.vue', () => {
  let wrapper;
  let dismissSpy;

  const createComponent = ({ shouldShowCallout = false } = {}) => {
    wrapper = mount(TopNavAppWithCallout, {
      propsData: {
        navData: TEST_NAV_DATA,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          shouldShowCallout,
          dismiss: dismissSpy,
        }),
      },
    });
  };

  const findTopNavApp = () => wrapper.findComponent(TopNavApp);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverContent = () => findPopover().find('[data-testid="popover-content"]');
  const findUserCalloutDismisser = () => wrapper.findComponent(UserCalloutDismisser);

  const triggerTopNavAppShown = () => findTopNavApp().vm.$emit('shown');
  const triggerPopoverContentClick = () => findPopoverContent().trigger('click');

  beforeEach(() => {
    dismissSpy = jest.fn();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders user callout dismisser', () => {
      expect(findUserCalloutDismisser().attributes('feature-name')).toBe('combined_menu_top_nav');
    });

    it('renders top nav app', () => {
      expect(findTopNavApp().props()).toEqual({
        navData: TEST_NAV_DATA,
      });
    });

    it('does not render popover', () => {
      expect(findPopover().exists()).toBe(false);
    });

    it('does not set seen', () => {
      expect(setSeenTopNav).not.toHaveBeenCalled();
    });

    describe('when top nav app shown', () => {
      beforeEach(() => {
        triggerTopNavAppShown();
      });

      it('does not dismiss', () => {
        expect(dismissSpy).not.toHaveBeenCalled();
      });

      it('sets seen', () => {
        expect(setSeenTopNav).toHaveBeenCalled();
      });
    });
  });

  describe('when shouldShowCallout=true', () => {
    beforeEach(() => {
      createComponent({ shouldShowCallout: true });
    });

    it('renders top nav app', () => {
      expect(findTopNavApp().props()).toEqual({
        navData: TEST_NAV_DATA,
      });
    });

    it('renders popover', () => {
      expect(findPopover().props()).toEqual(
        expect.objectContaining({
          triggers: 'manual',
          placement: 'bottomright',
        }),
      );

      expect(findPopover().attributes('show')).toBe('');
    });

    it('renders popover target', () => {
      const targetSelector = findPopover().props('target');

      const target = targetSelector();

      expect(target).toHaveClass('js-top-nav-dropdown-toggle');
    });

    it('renders popover content', () => {
      const message = cleanSprintfPlaceholders(TopNavAppWithCallout.MESSAGE);

      expect(findPopoverContent().text()).toBe(message);
    });

    it('renders help link', () => {
      const link = findPopoverContent().find('a');

      expect(link.text()).toBe('feedback issue');
      expect(link.attributes('href')).toBe(TopNavAppWithCallout.FEEDBACK_URL);
    });

    it('does not dismiss', () => {
      expect(dismissSpy).not.toHaveBeenCalled();
    });

    it('does not set seen', () => {
      expect(setSeenTopNav).not.toHaveBeenCalled();
    });

    describe.each`
      desc                             | triggerFn
      ${'when top nav shown'}          | ${triggerTopNavAppShown}
      ${'when popover content clicks'} | ${triggerPopoverContentClick}
    `('$desc', ({ triggerFn }) => {
      beforeEach(() => {
        triggerFn();
      });

      it('does dismiss', () => {
        expect(dismissSpy).toHaveBeenCalled();
      });

      it('sets seen', () => {
        expect(setSeenTopNav).toHaveBeenCalled();
      });
    });
  });
});

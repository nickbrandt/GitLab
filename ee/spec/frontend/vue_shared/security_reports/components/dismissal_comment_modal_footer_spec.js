import { mount } from '@vue/test-utils';
import Stats from 'ee/stats';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import component from 'ee/vue_shared/security_reports/components/dismissal_comment_modal_footer.vue';

jest.mock('ee/stats');

describe('DismissalCommentModalFooter', () => {
  let wrapper;

  describe('with an non-dismissed vulnerability', () => {
    beforeEach(() => {
      wrapper = mount(component, { sync: false });
    });

    it('should render the "Add comment and dismiss" button', () => {
      expect(wrapper.find(LoadingButton).text()).toBe('Add comment & dismiss');
    });

    it('should emit the "addCommentAndDismiss" event when clicked', () => {
      wrapper.find(LoadingButton).trigger('click');

      expect(wrapper.emitted().addCommentAndDismiss).toBeTruthy();
      expect(Stats.trackEvent).toHaveBeenCalledWith(
        document.body.dataset.page,
        'click_add_comment_and_dismiss',
      );
    });

    it('should emit the cancel event when the cancel button is clicked', () => {
      wrapper.find('.js-cancel').trigger('click');
      expect(wrapper.emitted().cancel).toBeTruthy();
    });
  });

  describe('with an already dismissed vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        isDismissed: true,
      };
      wrapper = mount(component, { propsData });
    });

    it('should render the "Add comment and dismiss" button', () => {
      expect(wrapper.find(LoadingButton).text()).toBe('Add comment');
    });

    it('should emit the "addCommentAndDismiss" event when clicked', () => {
      wrapper.find(LoadingButton).trigger('click');

      expect(wrapper.emitted().addDismissalComment).toBeTruthy();
      expect(Stats.trackEvent).toHaveBeenCalledWith(
        document.body.dataset.page,
        'click_add_comment',
      );
    });
  });
});

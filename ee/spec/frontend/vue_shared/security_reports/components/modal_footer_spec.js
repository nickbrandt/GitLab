import { mount } from '@vue/test-utils';
import component from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import DismissButton from 'ee/vue_shared/security_reports/components/dismiss_button.vue';
import createState from 'ee/vue_shared/security_reports/store/state';

describe('Security Reports modal footer', () => {
  let wrapper;

  describe('can only create issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
      };
      wrapper = mount(component, { propsData });
    });

    it('does not render dismiss button', () => {
      expect(wrapper.find('.js-dismiss-btn').exists()).toBe(false);
    });

    it('only renders the create issue button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Create issue');
      expect(wrapper.find(LoadingButton).props('label')).toBe('Create issue');
    });

    it('emits createIssue when create issue button is clicked', () => {
      wrapper.find(LoadingButton).trigger('click');
      expect(wrapper.emitted().createNewIssue).toBeTruthy();
    });
  });

  describe('can only create merge request', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateMergeRequest: true,
      };
      wrapper = mount(component, { propsData });
    });

    it('only renders the create merge request button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Create merge request');
      expect(wrapper.find(LoadingButton).props('label')).toBe('Create merge request');
    });

    it('emits createMergeRequest when create merge request button is clicked', () => {
      wrapper.find(LoadingButton).trigger('click');
      expect(wrapper.emitted().createMergeRequest).toBeTruthy();
    });
  });

  describe('can create merge request and issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
        canCreateMergeRequest: true,
      };
      wrapper = mount(component, { propsData });
    });

    it('renders the split button', () => {
      expect(wrapper.vm.actionButtons.length).toBe(2);
      expect(wrapper.find(SplitButton).exists()).toBe(true);
    });
  });

  describe('with dismissable vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canDismissVulnerability: true,
      };
      wrapper = mount(component, { propsData });
    });

    it('should render the dismiss button', () => {
      expect(wrapper.find(DismissButton).exists()).toBe(true);
    });
  });
});

import Vue from 'vue';
import { mount, createLocalVue } from '@vue/test-utils';
import { GlPopover } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import component from 'ee/approvals/components/approval_check_popover.vue';

describe('Approval Check Popover', () => {
  let wrapper;

  beforeEach(() => {
    const localVue = createLocalVue();
    wrapper = mount(component, {
      localVue,
      propsData: {
        title: 'Title',
      },
      sync: false,
    });
  });

  describe('with a documentation link', () => {
    const documentationLink = `${TEST_HOST}/documentation`;
    beforeEach(done => {
      wrapper.setProps({
        documentationLink,
      });
      Vue.nextTick(done);
    });

    it('should render the documentation link', () => {
      expect(
        wrapper
          .find(GlPopover)
          .find('a')
          .attributes('href'),
      ).toBe(documentationLink);
    });
  });

  describe('without a documentation link', () => {
    it('should not render the documentation link', () => {
      expect(
        wrapper
          .find(GlPopover)
          .find('a')
          .exists(),
      ).toBeFalsy();
    });
  });
});

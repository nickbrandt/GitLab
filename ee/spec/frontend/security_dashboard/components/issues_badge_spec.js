import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlPopover } from '@gitlab/ui';
import IssuesBadge from 'ee/security_dashboard/components/issues_badge.vue';
import IssueLink from 'ee/vulnerabilities/components/issue_link.vue';

describe('Remediated badge component', () => {
  const issues = [{ issue: { iid: 41 } }, { issue: { iid: 591 } }];
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);
  const findIssueLink = () => wrapper.findAll(IssueLink);
  const findPopover = () => wrapper.find(GlPopover);

  const createWrapper = ({ propsData }) => {
    return shallowMount(IssuesBadge, { propsData, stubs: { GlPopover } });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when there are multiple issues', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { issues } });
    });

    it('displays the correct icon', () => {
      expect(findIcon().props('name')).toBe('issues');
    });

    it('links the badge and the popover', () => {
      const { popover } = wrapper.vm.$refs;
      expect(popover.$attrs.target()).toEqual(findIcon().element.parentNode);
    });

    it('displays the issues', () => {
      expect(findIssueLink().length).toBe(issues.length);
    });

    it('displays the correct number of issues in the badge', () => {
      expect(wrapper.text()).toContain('2');
    });

    it('displays the correct number of issues in the popover title', () => {
      expect(findPopover().text()).toContain('2 Issues');
    });
  });

  describe('when there are no issues', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { issues: [] } });
    });

    it('displays the correct number of issues in the badge', () => {
      expect(wrapper.text()).toContain('0');
    });

    it('displays the correct number of issues in the popover title', () => {
      expect(findPopover().text()).toContain('0 Issues');
    });
  });
});

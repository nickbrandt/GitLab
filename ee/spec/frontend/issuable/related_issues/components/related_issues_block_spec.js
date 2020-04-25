import { mount } from '@vue/test-utils';
import RelatedIssuesBlock from 'ee/related_issues/components/related_issues_block.vue';
import {
  issuable1,
  issuable2,
  issuable3,
} from 'jest/vue_shared/components/issue/related_issuable_mock_data';
import {
  linkedIssueTypesMap,
  linkedIssueTypesTextMap,
  PathIdSeparator,
} from 'ee/related_issues/constants';

describe('RelatedIssuesBlock', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with defaults', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
        },
      });
    });

    it('displays "Linked issues" in the header', () => {
      expect(wrapper.find('h3').text()).toContain('Linked issues');
    });

    it('unable to add new related issues', () => {
      expect(wrapper.vm.$refs.issueCountBadgeAddButton).toBeUndefined();
    });

    it('add related issues form is hidden', () => {
      expect(wrapper.contains('.js-add-related-issues-form-area')).toBe(false);
    });
  });

  describe('with isFetching=true', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          isFetching: true,
          issuableType: 'issue',
        },
      });
    });

    it('should show `...` badge count', () => {
      expect(wrapper.vm.badgeLabel).toBe('...');
    });
  });

  describe('with canAddRelatedIssues=true', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          canAdmin: true,
          issuableType: 'issue',
        },
      });
    });

    it('can add new related issues', () => {
      expect(wrapper.vm.$refs.issueCountBadgeAddButton).toBeDefined();
    });
  });

  describe('with isFormVisible=true', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          isFormVisible: true,
          issuableType: 'issue',
        },
      });
    });

    it('shows add related issues form', () => {
      expect(wrapper.contains('.js-add-related-issues-form-area')).toBe(true);
    });
  });

  describe('with relatedIssues', () => {
    let categorizedHeadings;

    beforeEach(() => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2, issuable3],
          issuableType: 'issue',
        },
      });

      categorizedHeadings = wrapper.findAll('h4');
    });

    it('should render issue tokens items', () => {
      expect(wrapper.findAll('.js-related-issues-token-list-item')).toHaveLength(3);
    });

    it('shows "Blocks" heading', () => {
      const blocks = linkedIssueTypesTextMap[linkedIssueTypesMap.BLOCKS];

      expect(categorizedHeadings.at(0).text()).toBe(blocks);
    });

    it('shows "Is blocked by" heading', () => {
      const isBlockedBy = linkedIssueTypesTextMap[linkedIssueTypesMap.IS_BLOCKED_BY];

      expect(categorizedHeadings.at(1).text()).toBe(isBlockedBy);
    });

    it('shows "Relates to" heading', () => {
      const relatesTo = linkedIssueTypesTextMap[linkedIssueTypesMap.RELATES_TO];

      expect(categorizedHeadings.at(2).text()).toBe(relatesTo);
    });
  });

  describe('renders correct icon when', () => {
    [
      {
        icon: 'issues',
        issuableType: 'issue',
      },
      {
        icon: 'epic',
        issuableType: 'epic',
      },
    ].forEach(({ issuableType, icon }) => {
      it(`issuableType=${issuableType} is passed`, () => {
        wrapper = mount(RelatedIssuesBlock, {
          propsData: {
            pathIdSeparator: PathIdSeparator.Issue,
            issuableType,
          },
        });

        expect(wrapper.contains(`.issue-count-badge-count .ic-${icon}`)).toBe(true);
      });
    });
  });
});

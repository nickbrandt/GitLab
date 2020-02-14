import { mount } from '@vue/test-utils';
import RelatedIssuesBlock from 'ee/related_issues/components/related_issues_block.vue';
import {
  issuable1,
  issuable2,
  issuable3,
} from 'spec/vue_shared/components/issue/related_issuable_mock_data';
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
    beforeEach(() => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2],
          issuableType: 'issue',
        },
      });
    });

    it('should render issue tokens items', () => {
      expect(wrapper.findAll('.js-related-issues-token-list-item').length).toEqual(2);
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

  describe('with :issue_link_types feature flag on', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2, issuable3],
          issuableType: 'issue',
        },
        provide: {
          glFeatures: {
            issueLinkTypes: true,
          },
        },
      });
    });

    it('displays "Linked issues" in the header', () => {
      expect(wrapper.find('h3').text()).toContain('Linked issues');
    });

    describe('categorized headings', () => {
      let categorizedHeadings;

      beforeEach(() => {
        categorizedHeadings = wrapper.findAll('h4');
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
  });
});

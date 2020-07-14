import { shallowMount, mount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import {
  issuable1,
  issuable2,
  issuable3,
} from 'jest/vue_shared/components/issue/related_issuable_mock_data';
import {
  linkedIssueTypesMap,
  linkedIssueTypesTextMap,
  PathIdSeparator,
} from '~/related_issues/constants';

describe('RelatedIssuesBlock', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('showCategorizedIssues prop', () => {
    const issueList = () => wrapper.findAll('.js-related-issues-token-list-item');
    const categorizedHeadings = () => wrapper.findAll('h4');
    const headingTextAt = index =>
      categorizedHeadings()
        .at(index)
        .text();
    const mountComponent = showCategorizedIssues => {
      wrapper = mount(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2, issuable3],
          issuableType: 'issue',
          showCategorizedIssues,
        },
      });
    };

    describe('when showCategorizedIssues=true', () => {
      beforeEach(() => mountComponent(true));

      it('should render issue tokens items', () => {
        expect(issueList()).toHaveLength(3);
      });

      it('shows "Blocks" heading', () => {
        const blocks = linkedIssueTypesTextMap[linkedIssueTypesMap.BLOCKS];

        expect(headingTextAt(0)).toBe(blocks);
      });

      it('shows "Is blocked by" heading', () => {
        const isBlockedBy = linkedIssueTypesTextMap[linkedIssueTypesMap.IS_BLOCKED_BY];

        expect(headingTextAt(1)).toBe(isBlockedBy);
      });

      it('shows "Relates to" heading', () => {
        const relatesTo = linkedIssueTypesTextMap[linkedIssueTypesMap.RELATES_TO];

        expect(headingTextAt(2)).toBe(relatesTo);
      });
    });

    describe('when showCategorizedIssues=false', () => {
      it('should render issues as a flat list with no header', () => {
        mountComponent(false);

        expect(issueList()).toHaveLength(3);
        expect(categorizedHeadings()).toHaveLength(0);
      });
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
        wrapper = shallowMount(RelatedIssuesBlock, {
          propsData: {
            pathIdSeparator: PathIdSeparator.Issue,
            issuableType,
          },
        });

        const iconComponent = wrapper.find(GlIcon);
        expect(iconComponent.exists()).toBe(true);
        expect(iconComponent.props('name')).toBe(icon);
      });
    });
  });
});

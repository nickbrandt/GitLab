import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import IssueSubepicFlag from 'ee_component/issue/issue_subpepic_flag.vue';

const TEST_EPIC_ID = 36;
const TEST_ROOT_EPIC = { id: 36 };
const TEST_SUB_EPIC = { id: 37 };

describe('ee_component/issue/issue_subpepic_flag.vue', () => {
  let wrapper;

  const createWrapper = ({ issueEpic = TEST_ROOT_EPIC, filterEpicId = TEST_EPIC_ID }) => {
    wrapper = shallowMount(IssueSubepicFlag, {
      propsData: {
        issueEpic,
        filterEpicId,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findIcon = () => wrapper.find(GlIcon);

  describe('computed', () => {
    describe('issueInSubepic', () => {
      it('does not render an icon for direct children of the filter epic id', () => {
        createWrapper({ issueEpic: TEST_ROOT_EPIC, filterEpicId: TEST_EPIC_ID });
        expect(findIcon().exists()).toBeFalsy();
      });

      it('does not render an icon for non epic issues', () => {
        createWrapper({ issueEpic: undefined });
        expect(findIcon().exists()).toBeFalsy();
      });

      it('does not render an icon when not filtering by epic', () => {
        createWrapper({ filterEpicId: undefined });
        expect(findIcon().exists()).toBeFalsy();
      });

      it('renders an icon for sub-children of the filter epic id', () => {
        createWrapper({ issueEpic: TEST_SUB_EPIC, filterEpicId: TEST_EPIC_ID });
        expect(findIcon().exists()).toBeTruthy();
      });
    });
  });
});

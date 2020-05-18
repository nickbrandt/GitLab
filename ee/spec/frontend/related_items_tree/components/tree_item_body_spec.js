import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlDeprecatedButton, GlLink, GlIcon } from '@gitlab/ui';

import ItemWeight from 'ee/boards/components/issue_card_weight.vue';

import TreeItemBody from 'ee/related_items_tree/components/tree_item_body.vue';
import StateTooltip from 'ee/related_items_tree/components/state_tooltip.vue';

import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import { ChildType, ChildState } from 'ee/related_items_tree/constants';
import { PathIdSeparator } from 'ee/related_issues/constants';
import ItemAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import ItemDueDate from '~/boards/components/issue_due_date.vue';
import ItemMilestone from '~/vue_shared/components/issue/issue_milestone.vue';

import { mockParentItem, mockInitialConfig, mockQueryResponse, mockIssue1 } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const mockItem = {
  ...mockIssue1,
  type: ChildType.Issue,
  pathIdSeparator: PathIdSeparator.Issue,
  assignees: epicUtils.extractIssueAssignees(mockIssue1.assignees),
};

const createComponent = (parentItem = mockParentItem, item = mockItem) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    isSubItem: false,
    children,
  });
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });

  return shallowMount(TreeItemBody, {
    localVue,
    store,
    propsData: {
      parentItem,
      item,
    },
  });
};

const createEpicComponent = () => {
  const mockEpicItem = {
    ...mockItem,
    type: ChildType.Epic,
    healthStatus: mockParentItem.healthStatus,
    descendantCounts: {
      openedEpics: 0,
      closedEpics: 0,
      openedIssues: 0,
      closedIssues: 0,
    },
  };

  return createComponent(mockParentItem, mockEpicItem);
};

describe('RelatedItemsTree', () => {
  describe('TreeItemBody', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('computed', () => {
      describe('itemReference', () => {
        it('returns value of `item.reference` prop', () => {
          expect(wrapper.vm.itemReference).toBe(mockItem.reference);
        });
      });

      describe('itemWebPath', () => {
        const mockPath = '/foo/bar';

        it('returns value of `item.path`', () => {
          wrapper.setProps({
            item: { ...mockItem, path: mockPath, webPath: undefined },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.itemWebPath).toBe(mockPath);
          });
        });

        it('returns value of `item.webPath` when `item.path` is undefined', () => {
          wrapper.setProps({
            item: { ...mockItem, path: undefined, webPath: mockPath },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.itemWebPath).toBe(mockPath);
          });
        });
      });

      describe('isOpen', () => {
        it('returns true when `item.state` value is `opened`', () => {
          wrapper.setProps({
            item: { ...mockItem, state: ChildState.Open },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.isOpen).toBe(true);
          });
        });
      });

      describe('isClosed', () => {
        it('returns true when `item.state` value is `closed`', () => {
          wrapper.setProps({
            item: { ...mockItem, state: ChildState.Closed },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.isClosed).toBe(true);
          });
        });
      });

      describe('hasMilestone', () => {
        it('returns true when `item.milestone` is defined and has values', () => {
          expect(wrapper.vm.hasMilestone).toBe(true);
        });
      });

      describe('hasAssignees', () => {
        it('returns true when `item.assignees` is defined and has values', () => {
          expect(wrapper.vm.hasAssignees).toBe(true);
        });
      });

      describe('stateText', () => {
        it('returns string `Opened` when `item.state` value is `opened`', () => {
          wrapper.setProps({
            item: { ...mockItem, state: ChildState.Open },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateText).toBe('Opened');
          });
        });

        it('returns string `Closed` when `item.state` value is `closed`', () => {
          wrapper.setProps({
            item: { ...mockItem, state: ChildState.Closed },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateText).toBe('Closed');
          });
        });
      });

      describe('stateIconName', () => {
        it('returns string `issues` when `item.type` value is `issue`', () => {
          wrapper.setProps({
            item: { ...mockItem, type: ChildType.Issue },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateIconName).toBe('issues');
          });
        });

        it('returns string `epic` when `item.type` value is `epic`', () => {
          const epicItemWrapper = createEpicComponent();

          expect(epicItemWrapper.vm.stateIconName).toBe('epic');

          epicItemWrapper.destroy();
        });
      });

      describe('stateIconClass', () => {
        it('returns string `issue-token-state-icon-open` when `item.state` value is `opened`', () => {
          wrapper.setProps({
            item: { ...mockItem, state: ChildState.Open },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateIconClass).toBe('issue-token-state-icon-open');
          });
        });

        it('returns string `issue-token-state-icon-closed` when `item.state` value is `closed`', () => {
          wrapper.setProps({
            item: { ...mockItem, state: ChildState.Closed },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateIconClass).toBe('issue-token-state-icon-closed');
          });
        });
      });

      describe('itemId', () => {
        it('returns string containing item id', () => {
          expect(wrapper.vm.itemId).toBe('8');
        });
      });

      describe('itemPath', () => {
        it('returns string containing item path', () => {
          expect(wrapper.vm.itemPath).toBe('gitlab-org/gitlab-shell');
        });
      });

      describe('computedPath', () => {
        it('returns value of `itemWebPath` when it is defined', () => {
          expect(wrapper.vm.computedPath).toBe(mockItem.webPath);
        });

        it('returns `null` when `itemWebPath` is empty', () => {
          wrapper.setProps({
            item: { ...mockItem, webPath: '' },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.computedPath).toBeNull();
          });
        });
      });

      describe('isEpic', () => {
        it('returns false when item type is issue', () => {
          expect(wrapper.vm.isEpic).toBe(false);
        });

        it('returns true when item type is epic', () => {
          const epicItemWrapper = createEpicComponent();

          expect(epicItemWrapper.vm.isEpic).toBe(true);

          epicItemWrapper.destroy();
        });
      });
    });

    describe('methods', () => {
      describe('handleRemoveClick', () => {
        it('calls `setRemoveItemModalProps` action with params `parentItem` and `item`', () => {
          jest.spyOn(wrapper.vm, 'setRemoveItemModalProps');

          wrapper.vm.handleRemoveClick();

          expect(wrapper.vm.setRemoveItemModalProps).toHaveBeenCalledWith({
            parentItem: mockParentItem,
            item: mockItem,
          });
        });
      });
    });

    describe('template', () => {
      it('renders item body element without class `item-logged-out` when user is signed in', () => {
        expect(wrapper.find('.item-body').classes()).not.toContain('item-logged-out');
      });

      it('renders item body element without class `item-closed` when item state is opened', () => {
        expect(wrapper.find('.item-body').classes()).not.toContain('item-closed');
      });

      it('renders item state icon for large screens', () => {
        const statusIcon = wrapper.findAll(GlIcon).at(0);

        expect(statusIcon.props('name')).toBe('issues');
      });

      it('renders item state tooltip for large screens', () => {
        const stateTooltip = wrapper.findAll(StateTooltip).at(0);

        expect(stateTooltip.props('state')).toBe(mockItem.state);
      });

      it('renders item path in tooltip for large screens', () => {
        const stateTooltip = wrapper.findAll(StateTooltip).at(0);

        const { itemPath, itemId } = wrapper.vm;
        const path = itemPath + mockItem.pathIdSeparator + itemId;

        expect(stateTooltip.props('path')).toBe(path);
        expect(path).toContain('gitlab-org/gitlab-shell');
      });

      it('renders confidential icon when `item.confidential` is true', () => {
        const confidentialIcon = wrapper.findAll(GlIcon).at(1);

        expect(confidentialIcon.isVisible()).toBe(true);
        expect(confidentialIcon.props('name')).toBe('eye-slash');
      });

      it('renders item link', () => {
        const link = wrapper.find(GlLink);

        expect(link.attributes('href')).toBe(mockItem.webPath);
        expect(link.text()).toBe(mockItem.title);
      });

      it('renders item state tooltip for medium and small screens', () => {
        const stateTooltip = wrapper.findAll(StateTooltip).at(0);

        expect(stateTooltip.props('state')).toBe(mockItem.state);
      });

      it('renders item milestone when it has milestone', () => {
        const milestone = wrapper.find(ItemMilestone);

        expect(milestone.isVisible()).toBe(true);
      });

      it('renders item due date when it has due date', () => {
        const dueDate = wrapper.find(ItemDueDate);

        expect(dueDate.isVisible()).toBe(true);
      });

      it('renders item weight when it has weight', () => {
        const weight = wrapper.find(ItemWeight);

        expect(weight.isVisible()).toBe(true);
      });

      it('renders item assignees when it has assignees', () => {
        const assignees = wrapper.find(ItemAssignees);

        expect(assignees.isVisible()).toBe(true);
      });

      it('renders item remove button when `item.userPermissions.adminEpic` is true', () => {
        const removeButton = wrapper.find(GlDeprecatedButton);

        expect(removeButton.isVisible()).toBe(true);
        expect(removeButton.attributes('title')).toBe('Remove');
      });

      it('does not render issue count badge when item is issue', () => {
        expect(wrapper.find('.issue-count-badge').exists()).toBe(false);
      });

      it('render issue count badge when item is epic', () => {
        const epicWrapper = createEpicComponent();

        expect(epicWrapper.find('.issue-count-badge').exists()).toBe(true);

        epicWrapper.destroy();
      });

      it('renders health status when feature', () => {
        function testExistence(exists) {
          const healthStatus = wrapper.find('.item-health-status').exists();

          expect(healthStatus).toBe(exists);
        }

        testExistence(false);

        wrapper.vm.$store.commit('SET_INITIAL_CONFIG', {
          ...mockInitialConfig,
          allowIssuableHealthStatus: true,
        });

        return wrapper.vm.$nextTick(() => {
          testExistence(true);
        });
      });
    });
  });
});

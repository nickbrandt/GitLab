import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton, GlLink } from '@gitlab/ui';

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
import Icon from '~/vue_shared/components/icon.vue';

import {
  mockParentItem,
  mockInitialConfig,
  mockQueryResponse,
  mockIssue1,
} from '../../../javascripts/related_items_tree/mock_data';

const mockItem = Object.assign({}, mockIssue1, {
  type: ChildType.Issue,
  pathIdSeparator: PathIdSeparator.Issue,
  assignees: epicUtils.extractIssueAssignees(mockIssue1.assignees),
});

const localVue = createLocalVue();

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
    attachToDocument: true,
    sync: false,
    localVue,
    store,
    propsData: {
      parentItem,
      item,
    },
  });
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

        it('returns value of `item.path`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              path: mockPath,
              webPath: undefined,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.itemWebPath).toBe(mockPath);

            done();
          });
        });

        it('returns value of `item.webPath` when `item.path` is undefined', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              path: undefined,
              webPath: mockPath,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.itemWebPath).toBe(mockPath);

            done();
          });
        });
      });

      describe('isOpen', () => {
        it('returns true when `item.state` value is `opened`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              state: ChildState.Open,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.isOpen).toBe(true);

            done();
          });
        });
      });

      describe('isClosed', () => {
        it('returns true when `item.state` value is `closed`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              state: ChildState.Closed,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.isClosed).toBe(true);

            done();
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
        it('returns string `Opened` when `item.state` value is `opened`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              state: ChildState.Open,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateText).toBe('Opened');

            done();
          });
        });

        it('returns string `Closed` when `item.state` value is `closed`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              state: ChildState.Closed,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateText).toBe('Closed');

            done();
          });
        });
      });

      describe('stateIconName', () => {
        it('returns string `epic` when `item.type` value is `epic`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              type: ChildType.Epic,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateIconName).toBe('epic');

            done();
          });
        });

        it('returns string `issues` when `item.type` value is `issue`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              type: ChildType.Issue,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateIconName).toBe('issues');

            done();
          });
        });
      });

      describe('stateIconClass', () => {
        it('returns string `issue-token-state-icon-open` when `item.state` value is `opened`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              state: ChildState.Open,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateIconClass).toBe('issue-token-state-icon-open');

            done();
          });
        });

        it('returns string `issue-token-state-icon-closed` when `item.state` value is `closed`', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              state: ChildState.Closed,
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateIconClass).toBe('issue-token-state-icon-closed');

            done();
          });
        });
      });

      describe('itemPath', () => {
        it('returns string containing item path', () => {
          expect(wrapper.vm.itemPath).toBe('gitlab-org/gitlab-shell');
        });
      });

      describe('itemId', () => {
        it('returns string containing item id', () => {
          expect(wrapper.vm.itemId).toBe('8');
        });
      });

      describe('computedPath', () => {
        it('returns value of `itemWebPath` when it is defined', () => {
          expect(wrapper.vm.computedPath).toBe(mockItem.webPath);
        });

        it('returns `null` when `itemWebPath` is empty', done => {
          wrapper.setProps({
            item: Object.assign({}, mockItem, {
              webPath: '',
            }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.computedPath).toBeNull();

            done();
          });
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
        const statusIcon = wrapper.findAll(Icon).at(0);

        expect(statusIcon.props('name')).toBe('issues');
      });

      it('renders item state tooltip for large screens', () => {
        const stateTooltip = wrapper.findAll(StateTooltip).at(0);

        expect(stateTooltip.props('state')).toBe(mockItem.state);
      });

      it('renders confidential icon when `item.confidential` is true', () => {
        const confidentialIcon = wrapper.findAll(Icon).at(1);

        expect(confidentialIcon.isVisible()).toBe(true);
        expect(confidentialIcon.props('name')).toBe('eye-slash');
      });

      it('renders item link', () => {
        const link = wrapper.find(GlLink);

        expect(link.attributes('href')).toBe(mockItem.webPath);
        expect(link.text()).toBe(mockItem.title);
      });

      it('renders item state icon for medium and small screens', () => {
        const statusIcon = wrapper.findAll(Icon).at(2);

        expect(statusIcon.props('name')).toBe('issues');
      });

      it('renders item state tooltip for medium and small screens', () => {
        const stateTooltip = wrapper.findAll(StateTooltip).at(1);

        expect(stateTooltip.props('state')).toBe(mockItem.state);
      });

      it('renders item path', () => {
        const pathEl = wrapper.find('.path-id-text');

        expect(pathEl.attributes('title')).toBe('gitlab-org/gitlab-shell');
        expect(pathEl.text()).toBe('gitlab-org/gitlab-shell');
      });

      it('renders item id with separator', () => {
        const pathIdEl = wrapper.find('.item-path-id');

        expect(pathIdEl.text()).toBe(mockItem.reference);
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
        const removeButton = wrapper.find(GlButton);

        expect(removeButton.isVisible()).toBe(true);
        expect(removeButton.attributes('title')).toBe('Remove');
      });
    });
  });
});

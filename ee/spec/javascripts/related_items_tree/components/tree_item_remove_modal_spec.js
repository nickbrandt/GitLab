import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';

import TreeItemRemoveModal from 'ee/related_items_tree/components/tree_item_remove_modal.vue';

import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import { ChildType } from 'ee/related_items_tree/constants';
import { PathIdSeparator } from 'ee/related_issues/constants';

import { mockParentItem, mockQueryResponse, mockIssue1 } from '../mock_data';

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
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    isSubItem: false,
    children,
  });
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });
  store.dispatch('setRemoveItemModalProps', {
    parentItem,
    item,
  });

  return shallowMount(localVue.extend(TreeItemRemoveModal), {
    localVue,
    store,
  });
};

describe('RelatedItemsTree', () => {
  describe('TreeItemRemoveModal', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('computed', () => {
      describe('removeItemType', () => {
        it('returns value of `state.removeItemModalProps.item.type', () => {
          expect(wrapper.vm.removeItemType).toBe(mockItem.type);
        });
      });

      describe('modalTitle', () => {
        it('returns title for modal when item.type is `Epic`', done => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: Object.assign({}, mockItem, { type: ChildType.Epic }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalTitle).toBe('Remove epic');

            done();
          });
        });

        it('returns title for modal when item.type is `Issue`', done => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: mockItem,
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalTitle).toBe('Remove issue');

            done();
          });
        });
      });

      describe('modalBody', () => {
        it('returns body text for modal when item.type is `Epic`', done => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: Object.assign({}, mockItem, { type: ChildType.Epic }),
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalBody).toBe(
              'This will also remove any descendents of <b>Nostrum cum mollitia quia recusandae fugit deleniti voluptatem delectus.</b> from <b>Some sample epic</b>. Are you sure?',
            );

            done();
          });
        });

        it('returns body text for modal when item.type is `Issue`', done => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: mockItem,
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalBody).toBe(
              'Are you sure you want to remove <b>Nostrum cum mollitia quia recusandae fugit deleniti voluptatem delectus.</b> from <b>Some sample epic</b>?',
            );

            done();
          });
        });
      });
    });

    describe('template', () => {
      it('renders modal component', () => {
        const modal = wrapper.find(GlModal);

        expect(modal.isVisible()).toBe(true);
        expect(modal.attributes('modalid')).toBe('item-remove-confirmation');
        expect(modal.attributes('ok-title')).toBe('Remove');
        expect(modal.attributes('ok-variant')).toBe('danger');
      });
    });
  });
});

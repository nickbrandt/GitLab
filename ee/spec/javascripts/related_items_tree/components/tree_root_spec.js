import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

import TreeRoot from 'ee/related_items_tree/components/tree_root.vue';

import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import { mockQueryResponse, mockParentItem } from '../mock_data';

const { epic } = mockQueryResponse.data.group;

const createComponent = ({
  parentItem = mockParentItem,
  epicPageInfo = epic.children.pageInfo,
  issuesPageInfo = epic.issues.pageInfo,
} = {}) => {
  const store = createDefaultStore();
  const localVue = createLocalVue();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });

  store.dispatch('setEpicPageInfo', {
    parentItem,
    pageInfo: epicPageInfo,
  });

  store.dispatch('setIssuePageInfo', {
    parentItem,
    pageInfo: issuesPageInfo,
  });

  return shallowMount(TreeRoot, {
    localVue,
    store,
    stubs: {
      'tree-item': true,
      'gl-button': GlButton,
    },
    propsData: {
      parentItem,
      children,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('TreeRoot', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('computed', () => {
      describe('hasMoreChildren', () => {
        it('returns `true` when either `hasMoreEpics` or `hasMoreIssues` is true', () => {
          expect(wrapper.vm.hasMoreChildren).toBe(true);
        });

        it('returns `false` when both `hasMoreEpics` and `hasMoreIssues` is false', () => {
          const wrapperNoMoreChild = createComponent({
            epicPageInfo: {
              hasNextPage: false,
              endCursor: 'abc',
            },
            issuesPageInfo: {
              hasNextPage: false,
              endCursor: 'def',
            },
          });

          expect(wrapperNoMoreChild.vm.hasMoreChildren).toBe(false);

          wrapperNoMoreChild.destroy();
        });
      });
    });

    describe('methods', () => {
      describe('handleShowMoreClick', () => {
        it('sets `fetchInProgress` to true and calls `fetchNextPageItems` action with parentItem as param', () => {
          spyOn(wrapper.vm, 'fetchNextPageItems').and.callFake(() => new Promise(() => {}));

          wrapper.vm.handleShowMoreClick();

          expect(wrapper.vm.fetchInProgress).toBe(true);
          expect(wrapper.vm.fetchNextPageItems).toHaveBeenCalledWith(
            jasmine.objectContaining({
              parentItem: mockParentItem,
            }),
          );
        });
      });
    });

    describe('template', () => {
      it('renders tree item component', () => {
        expect(wrapper.html()).toContain('tree-item-stub');
      });

      it('renders `Show more` link', () => {
        expect(wrapper.find('button').text()).toBe('Show more');
      });

      it('calls `handleShowMoreClick` when `Show more` link is clicked', () => {
        spyOn(wrapper.vm, 'handleShowMoreClick');

        wrapper.find('button').trigger('click');

        expect(wrapper.vm.handleShowMoreClick).toHaveBeenCalled();
      });
    });
  });
});

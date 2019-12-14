import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

import Draggable from 'vuedraggable';

import TreeRoot from 'ee/related_items_tree/components/tree_root.vue';

import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import {
  mockQueryResponse,
  mockInitialConfig,
  mockParentItem,
  mockEpic1,
  mockIssue2,
} from '../mock_data';

const { epic } = mockQueryResponse.data.group;

const localVue = createLocalVue();

const createComponent = ({
  parentItem = mockParentItem,
  epicPageInfo = epic.children.pageInfo,
  issuesPageInfo = epic.issues.pageInfo,
} = {}) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setInitialConfig', mockInitialConfig);
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

  return shallowMount(localVue.extend(TreeRoot), {
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
    sync: false,
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

    describe('mixins', () => {
      describe('TreeDragAndDropMixin', () => {
        const containedDragClassOriginally = document.body.classList.contains('is-dragging');
        const containedNoDropClassOriginally = document.body.classList.contains('no-drop');

        beforeEach(() => {
          document.body.classList.remove('is-dragging');
          document.body.classList.remove('no-drop');
        });

        afterAll(() => {
          // Prevent side-effects of this test.
          document.body.classList.toggle('is-dragging', containedDragClassOriginally);
          document.body.classList.toggle('no-drop', containedNoDropClassOriginally);
        });

        describe('computed', () => {
          describe('treeRootWrapper', () => {
            it('should return Draggable reference when userSignedIn prop is true', () => {
              expect(wrapper.vm.treeRootWrapper).toBe(Draggable);
            });

            it('should return string "ul" when userSignedIn prop is false', () => {
              wrapper.vm.$store.dispatch('setInitialConfig', {
                ...mockInitialConfig,
                userSignedIn: false,
              });

              expect(wrapper.vm.treeRootWrapper).toBe('ul');
            });
          });

          describe('treeRootOptions', () => {
            it('should return object containing Vue.Draggable config extended from `defaultSortableConfig` when userSignedIn prop is true', () => {
              expect(wrapper.vm.treeRootOptions).toEqual(
                jasmine.objectContaining({
                  animation: 200,
                  forceFallback: true,
                  fallbackClass: 'is-dragging',
                  fallbackOnBody: false,
                  ghostClass: 'is-ghost',
                  group: mockParentItem.reference,
                  tag: 'ul',
                  'ghost-class': 'tree-item-drag-active',
                  'data-parent-reference': mockParentItem.reference,
                  value: wrapper.vm.children,
                }),
              );
            });

            it('should return an empty object when userSignedIn prop is false', () => {
              wrapper.vm.$store.dispatch('setInitialConfig', {
                ...mockInitialConfig,
                userSignedIn: false,
              });

              expect(wrapper.vm.treeRootOptions).toEqual(jasmine.objectContaining({}));
            });
          });
        });

        describe('methods', () => {
          describe('getItemId', () => {
            it('returns value of `id` prop when item is an Epic', () => {
              expect(wrapper.vm.getItemId(wrapper.vm.children[0])).toBe(mockEpic1.id);
            });

            it('returns value of `epicIssueId` prop when item is an Issue', () => {
              expect(wrapper.vm.getItemId(wrapper.vm.children[2])).toBe(mockIssue2.epicIssueId);
            });
          });

          describe('getTreeReorderMutation', () => {
            it('returns an object containing ID of targetItem', () => {
              const targetItemEpic = wrapper.vm.children[0];
              const targetItemIssue = wrapper.vm.children[2];
              const newIndex = 0;

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem: targetItemEpic,
                  newIndex,
                }),
              ).toEqual(
                jasmine.objectContaining({
                  id: mockEpic1.id,
                }),
              );

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem: targetItemIssue,
                  newIndex,
                }),
              ).toEqual(
                jasmine.objectContaining({
                  id: mockIssue2.epicIssueId,
                }),
              );
            });

            it('returns an object containing `adjacentReferenceId` of children item at provided `newIndex`', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 0,
                }),
              ).toEqual(
                jasmine.objectContaining({
                  adjacentReferenceId: mockEpic1.id,
                }),
              );

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 2,
                }),
              ).toEqual(
                jasmine.objectContaining({
                  adjacentReferenceId: mockIssue2.epicIssueId,
                }),
              );
            });

            it('returns object containing `relativePosition` containing `after` when `newIndex` param is 0', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 0,
                }),
              ).toEqual(
                jasmine.objectContaining({
                  relativePosition: 'after',
                }),
              );
            });

            it('returns object containing `relativePosition` containing `before` when `newIndex` param is last item index', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: wrapper.vm.children.length - 1,
                }),
              ).toEqual(
                jasmine.objectContaining({
                  relativePosition: 'before',
                }),
              );
            });

            it('returns object containing `relativePosition` containing `after` when `newIndex` param neither `0` nor last item index', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 2,
                }),
              ).toEqual(
                jasmine.objectContaining({
                  relativePosition: 'after',
                }),
              );
            });
          });

          describe('handleDragOnStart', () => {
            it('adds a class `is-dragging` to document body', () => {
              expect(document.body.classList.contains('is-dragging')).toBe(false);

              wrapper.vm.handleDragOnStart();

              expect(document.body.classList.contains('is-dragging')).toBe(true);
            });
          });

          describe('handleDragOnEnd', () => {
            it('removes class `is-dragging` from document body', () => {
              spyOn(wrapper.vm, 'reorderItem').and.stub();
              document.body.classList.add('is-dragging');

              wrapper.vm.handleDragOnEnd({
                oldIndex: 1,
                newIndex: 0,
              });

              expect(document.body.classList.contains('is-dragging')).toBe(false);
            });

            it('does not call `reorderItem` action when newIndex is same as oldIndex', () => {
              spyOn(wrapper.vm, 'reorderItem').and.stub();

              wrapper.vm.handleDragOnEnd({
                oldIndex: 0,
                newIndex: 0,
              });

              expect(wrapper.vm.reorderItem).not.toHaveBeenCalled();
            });

            it('calls `reorderItem` action when newIndex is different from oldIndex', () => {
              spyOn(wrapper.vm, 'reorderItem').and.stub();

              wrapper.vm.handleDragOnEnd({
                oldIndex: 1,
                newIndex: 0,
              });

              expect(wrapper.vm.reorderItem).toHaveBeenCalledWith(
                jasmine.objectContaining({
                  treeReorderMutation: jasmine.any(Object),
                  parentItem: wrapper.vm.parentItem,
                  targetItem: wrapper.vm.children[1],
                  oldIndex: 1,
                  newIndex: 0,
                }),
              );
            });
          });
        });
      });
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

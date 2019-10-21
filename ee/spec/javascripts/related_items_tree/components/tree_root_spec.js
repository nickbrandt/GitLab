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
  mockIssue1,
} from '../mock_data';

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
                  move: wrapper.vm.handleDragOnMove,
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
          describe('getTreeReorderMutation', () => {
            it('returns an object containing `id`, `adjacentReferenceId` & `relativePosition` when newIndex param is 0 and targetItem is Epic', () => {
              const targetItem = wrapper.vm.children[1]; // 2nd Epic position
              const newIndex = 0; // We're moving targetItem to top of Epics list & Epics begin at 0

              const treeReorderMutation = wrapper.vm.getTreeReorderMutation({
                targetItem,
                newIndex,
              });

              expect(treeReorderMutation).toEqual(
                jasmine.objectContaining({
                  id: targetItem.id,
                  adjacentReferenceId: mockEpic1.id,
                  relativePosition: 'after',
                }),
              );
            });

            it('returns an object containing `id`, `adjacentReferenceId` & `relativePosition` when newIndex param is 1 and targetItem is Epic', () => {
              const targetItem = wrapper.vm.children[0];
              const newIndex = 1;

              const treeReorderMutation = wrapper.vm.getTreeReorderMutation({
                targetItem,
                newIndex,
              });

              expect(treeReorderMutation).toEqual(
                jasmine.objectContaining({
                  id: targetItem.id,
                  adjacentReferenceId: mockEpic1.id,
                  relativePosition: 'before',
                }),
              );
            });

            it('returns an object containing `id`, `adjacentReferenceId` & `relativePosition` when newIndex param is 0 and targetItem is Issue', () => {
              const targetItem = wrapper.vm.children[3]; // 2nd Issue position
              const newIndex = 2; // We're moving targetItem to top of Issues list & Issues begin at 2

              const treeReorderMutation = wrapper.vm.getTreeReorderMutation({
                targetItem,
                newIndex,
              });

              expect(treeReorderMutation).toEqual(
                jasmine.objectContaining({
                  id: targetItem.epicIssueId,
                  adjacentReferenceId: mockIssue1.epicIssueId,
                  relativePosition: 'after',
                }),
              );
            });

            it('returns an object containing `id`, `adjacentReferenceId` & `relativePosition` when newIndex param is 1 and targetItem is Issue', () => {
              const targetItem = wrapper.vm.children[2];
              const newIndex = 3; // Here 3 is first issue of the list, hence spec descripton says `newIndex` as 1.

              const treeReorderMutation = wrapper.vm.getTreeReorderMutation({
                targetItem,
                newIndex,
              });

              expect(treeReorderMutation).toEqual(
                jasmine.objectContaining({
                  id: targetItem.epicIssueId,
                  adjacentReferenceId: mockIssue1.epicIssueId,
                  relativePosition: 'before',
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

          describe('handleDragOnMove', () => {
            let dragged;
            let related;
            let mockEvent;

            beforeEach(() => {
              dragged = document.createElement('li');
              related = document.createElement('li');
              mockEvent = {
                dragged,
                related,
              };
            });

            it('returns `true` when an epic is reordered within epics list', () => {
              dragged.classList.add('js-item-type-epic');
              related.classList.add('js-item-type-epic');

              expect(wrapper.vm.handleDragOnMove(mockEvent)).toBe(true);
            });

            it('returns `true` when an issue is reordered within issues list', () => {
              dragged.classList.add('js-item-type-issue');
              related.classList.add('js-item-type-issue');

              expect(wrapper.vm.handleDragOnMove(mockEvent)).toBe(true);
            });

            it('returns `false` when an issue is reordered within epics list', () => {
              dragged.classList.add('js-item-type-issue');
              related.classList.add('js-item-type-epic');

              expect(wrapper.vm.handleDragOnMove(mockEvent)).toBe(false);
            });

            it('returns `false` when an epic is reordered within issues list', () => {
              dragged.classList.add('js-item-type-epic');
              related.classList.add('js-item-type-issue');

              expect(wrapper.vm.handleDragOnMove(mockEvent)).toBe(false);
            });

            it('adds class `no-drop` to body element when reordering is not allowed', () => {
              dragged.classList.add('js-item-type-epic');
              related.classList.add('js-item-type-issue');

              wrapper.vm.handleDragOnMove(mockEvent);

              expect(document.body.classList.contains('no-drop')).toBe(true);
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

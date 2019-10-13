import defaultSortableConfig from '~/sortable/sortable_config';
import { ChildType, idProp, relativePositions } from '../constants';

export default {
  computed: {
    dragOptions() {
      return {
        ...defaultSortableConfig,
        fallbackOnBody: false,
        group: this.parentItem.reference,
      };
    },
  },
  methods: {
    /**
     * This method returns an object containing
     *  - `id` Global ID of target item.
     *  - `adjacentReferenceId` Global ID of adjacent item that's
     *                          either above or below new position of target item.
     *  - `relativePosition` String representation of adjacent item which can be
     *                       either `above` or `below`.
     *
     * Note: Current implementation of this method handles Epics and Issues separately
     *       But once we support interspersed reordering, we won't need to treat
     *       them separately.
     *
     * @param {number} object.newIndex new position of target item
     * @param {object} object.targetItem target item object
     */
    getTreeReorderMutation({ newIndex, targetItem }) {
      const currentItemEpicsBeginAtIndex = 0;
      const { currentItemIssuesBeginAtIndex, children } = this;
      const isEpic = targetItem.type === ChildType.Epic;
      const idPropVal = idProp[targetItem.type];
      let adjacentReferenceId;
      let relativePosition;

      // This condition does either of the two checks as follows;
      // 1. If target item is of type *Epic* and newIndex is *NOT* on top of Epics list.
      // 2. If target item is of type *Issue* and newIndex is *NOT* on top of Issues list.
      if (
        (isEpic && newIndex > currentItemEpicsBeginAtIndex) ||
        (!isEpic && newIndex > currentItemIssuesBeginAtIndex)
      ) {
        // We set `adjacentReferenceId` to the item ID that's _above_ the target items new position.
        // And since adjacent item is above, we set `relativePosition` to `Before`.
        adjacentReferenceId = children[newIndex - 1][idPropVal];
        relativePosition = relativePositions.Before;
      } else {
        // We set `adjacentReferenceId` to the item ID that's on top of the list (either Epics or Issues)
        // And since adjacent item is below, we set `relativePosition` to `After`.
        adjacentReferenceId =
          children[isEpic ? currentItemEpicsBeginAtIndex : currentItemIssuesBeginAtIndex][
            idPropVal
          ];
        relativePosition = relativePositions.After;
      }

      return {
        id: targetItem[idPropVal],
        adjacentReferenceId,
        relativePosition,
      };
    },
    /**
     * This event handler is triggered the moment dragging
     * of item is started, and it sets `is-dragging` class
     * to page body.
     */
    handleDragOnStart() {
      document.body.classList.add('is-dragging');
    },
    /**
     * This event handler is constantly fired as user is dragging
     * the item around the UI.
     *
     * This method returns boolean value based on following
     * condition checks, thus preventing interspersed ordering;
     * 1. If item being dragged is Epic,
     *    and it is moved on top of Issues; return `false`
     * 2. If item being dragged is Issue,
     *    and it is moved on top of Epics; return `false`.
     * 3. If above two conditions are not met; return `true`.
     *
     * @param {object} event Object representing drag move event.
     */
    handleDragOnMove({ dragged, related }) {
      let isAllowed = false;

      if (dragged.classList.contains('js-item-type-epic')) {
        isAllowed = related.classList.contains('js-item-type-epic');
      } else {
        isAllowed = related.classList.contains('js-item-type-issue');
      }

      document.body.classList.toggle('no-drop', !isAllowed);

      return isAllowed;
    },
    /**
     * This event handler is fired when user releases the dragging
     * item.
     *
     * This method actually fires Vuex action `reorderItem`
     * that performs GraphQL mutation to update item order
     * within tree.
     *
     * @param {object} event Object representing drag end event.
     */
    handleDragOnEnd({ oldIndex, newIndex }) {
      document.body.classList.remove('is-dragging');

      // If both old and new index of target are same,
      // nothing was moved, we do an early return.
      if (oldIndex === newIndex) return;

      const targetItem = this.children[oldIndex];

      this.reorderItem({
        treeReorderMutation: this.getTreeReorderMutation({ newIndex, targetItem }),
        parentItem: this.parentItem,
        targetItem,
        oldIndex,
        newIndex,
      });
    },
  },
};

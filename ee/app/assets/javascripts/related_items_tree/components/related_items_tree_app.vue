<script>
import { mapState, mapActions, mapGetters } from 'vuex';

import { GlLoadingIcon } from '@gitlab/ui';

import { issuableTypesMap } from 'ee/related_issues/constants';

import SlotSwitch from '~/vue_shared/components/slot_switch.vue';
import AddItemForm from 'ee/related_issues/components/add_issuable_form.vue';
import CreateEpicForm from './create_epic_form.vue';
import CreateIssueForm from './create_issue_form.vue';
import IssueActionsSplitButton from './issue_actions_split_button.vue';
import TreeItemRemoveModal from './tree_item_remove_modal.vue';

import RelatedItemsTreeHeader from './related_items_tree_header.vue';
import RelatedItemsTreeBody from './related_items_tree_body.vue';

import { OVERFLOW_AFTER } from '../constants';

const FORM_SLOTS = {
  addItem: 'addItem',
  createEpic: 'createEpic',
  createIssue: 'createIssue',
};

export default {
  OVERFLOW_AFTER,
  FORM_SLOTS,
  components: {
    GlLoadingIcon,
    RelatedItemsTreeHeader,
    RelatedItemsTreeBody,
    AddItemForm,
    CreateEpicForm,
    TreeItemRemoveModal,
    CreateIssueForm,
    IssueActionsSplitButton,
    SlotSwitch,
  },
  data() {
    return {
      isCreateIssueFormVisible: false,
    };
  },
  computed: {
    ...mapState([
      'parentItem',
      'itemsFetchInProgress',
      'itemsFetchResultEmpty',
      'itemAddInProgress',
      'itemAddFailure',
      'itemAddFailureType',
      'itemCreateInProgress',
      'showAddItemForm',
      'showCreateEpicForm',
      'autoCompleteEpics',
      'autoCompleteIssues',
      'pendingReferences',
      'itemInputValue',
      'issuableType',
      'epicsEndpoint',
      'issuesEndpoint',
    ]),
    ...mapGetters(['itemAutoCompleteSources', 'itemPathIdSeparator', 'directChildren']),
    disableContents() {
      return this.itemAddInProgress || this.itemCreateInProgress;
    },
    createIssueEnabled() {
      return gon.features && gon.features.epicNewIssue;
    },
    visibleForm() {
      if (this.showAddItemForm) {
        return FORM_SLOTS.addItem;
      }

      if (this.showCreateEpicForm) {
        return FORM_SLOTS.createEpic;
      }

      if (this.isCreateIssueFormVisible) {
        return FORM_SLOTS.createIssue;
      }

      return null;
    },
  },
  mounted() {
    this.fetchItems({
      parentItem: this.parentItem,
    });
  },
  methods: {
    ...mapActions([
      'fetchItems',
      'toggleAddItemForm',
      'toggleCreateEpicForm',
      'setPendingReferences',
      'addPendingReferences',
      'removePendingReference',
      'setItemInputValue',
      'addItem',
      'createItem',
    ]),
    getRawRefs(value) {
      return value.split(/\s+/).filter(ref => ref.trim().length > 0);
    },
    handlePendingItemRemove(index) {
      this.removePendingReference(index);
    },
    handleAddItemFormInput({ untouchedRawReferences, touchedReference }) {
      this.addPendingReferences(untouchedRawReferences);
      this.setItemInputValue(`${touchedReference}`);
    },
    handleAddItemFormBlur(newValue) {
      this.addPendingReferences(this.getRawRefs(newValue));
      this.setItemInputValue('');
    },
    handleAddItemFormSubmit(newValue) {
      this.handleAddItemFormBlur(newValue);

      if (this.pendingReferences.length > 0) {
        this.addItem();
      }
    },
    handleCreateEpicFormSubmit(newValue) {
      this.createItem({
        itemTitle: newValue,
      });
    },
    handleAddItemFormCancel() {
      this.toggleAddItemForm({ toggleState: false });
      this.setPendingReferences([]);
      this.setItemInputValue('');
    },
    handleCreateEpicFormCancel() {
      this.toggleCreateEpicForm({ toggleState: false });
      this.setItemInputValue('');
    },
    showAddIssueForm() {
      this.toggleAddItemForm({ toggleState: true, issuableType: issuableTypesMap.ISSUE });
    },
    showCreateIssueForm() {
      this.toggleAddItemForm({ toggleState: false });
      this.toggleCreateEpicForm({ toggleState: false });
      this.isCreateIssueFormVisible = true;
    },
  },
};
</script>

<template>
  <div class="related-items-tree-container">
    <div v-if="itemsFetchInProgress" class="mt-2">
      <gl-loading-icon size="md" />
    </div>
    <div
      v-else
      class="related-items-tree card card-slim border-top-0"
      :class="{
        'disabled-content': disableContents,
        'overflow-auto': directChildren.length > $options.OVERFLOW_AFTER,
      }"
    >
      <related-items-tree-header :class="{ 'border-bottom-0': itemsFetchResultEmpty }">
        <issue-actions-split-button
          v-if="createIssueEnabled"
          slot="issueActions"
          class="ml-1"
          @showAddIssueForm="showAddIssueForm"
          @showCreateIssueForm="showCreateIssueForm"
        />
      </related-items-tree-header>
      <slot-switch
        v-if="visibleForm"
        :active-slot-names="[visibleForm]"
        class="card-body add-item-form-container"
        :class="{
          'border-bottom-0': itemsFetchResultEmpty,
          'gl-show-field-errors': itemAddFailure,
        }"
      >
        <add-item-form
          :slot="$options.FORM_SLOTS.addItem"
          :issuable-type="issuableType"
          :input-value="itemInputValue"
          :is-submitting="itemAddInProgress"
          :pending-references="pendingReferences"
          :auto-complete-sources="itemAutoCompleteSources"
          :path-id-separator="itemPathIdSeparator"
          :has-error="itemAddFailure"
          :item-add-failure-type="itemAddFailureType"
          @pendingIssuableRemoveRequest="handlePendingItemRemove"
          @addIssuableFormInput="handleAddItemFormInput"
          @addIssuableFormBlur="handleAddItemFormBlur"
          @addIssuableFormSubmit="handleAddItemFormSubmit"
          @addIssuableFormCancel="handleAddItemFormCancel"
        />
        <create-epic-form
          :slot="$options.FORM_SLOTS.createEpic"
          :is-submitting="itemCreateInProgress"
          @createEpicFormSubmit="handleCreateEpicFormSubmit"
          @createEpicFormCancel="handleCreateEpicFormCancel"
        />
        <create-issue-form
          :slot="$options.FORM_SLOTS.createIssue"
          @cancel="isCreateIssueFormVisible = false"
        />
      </slot-switch>
      <related-items-tree-body
        v-if="!itemsFetchResultEmpty"
        :parent-item="parentItem"
        :children="directChildren"
      />
      <tree-item-remove-modal />
    </div>
  </div>
</template>

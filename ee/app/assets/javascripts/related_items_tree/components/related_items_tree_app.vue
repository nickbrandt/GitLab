<script>
import { mapState, mapActions, mapGetters } from 'vuex';

import { GlLoadingIcon } from '@gitlab/ui';

import { issuableTypesMap } from 'ee/related_issues/constants';

import AddItemForm from 'ee/related_issues/components/add_issuable_form.vue';
import CreateEpicForm from './create_epic_form.vue';
import CreateIssueForm from './create_issue_form.vue';
import IssueActionsSplitButton from './issue_actions_split_button.vue';
import TreeItemRemoveModal from './tree_item_remove_modal.vue';

import RelatedItemsTreeHeader from './related_items_tree_header.vue';
import RelatedItemsTreeBody from './related_items_tree_body.vue';

import { PathIdSeparator, OVERFLOW_AFTER } from '../constants';

export default {
  PathIdSeparator,
  OVERFLOW_AFTER,
  components: {
    GlLoadingIcon,
    RelatedItemsTreeHeader,
    RelatedItemsTreeBody,
    AddItemForm,
    CreateEpicForm,
    TreeItemRemoveModal,
    CreateIssueForm,
    IssueActionsSplitButton,
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
      <div
        v-if="showAddItemForm || showCreateEpicForm || isCreateIssueFormVisible"
        class="card-body add-item-form-container"
        :class="{ 'border-bottom-0': itemsFetchResultEmpty }"
      >
        <add-item-form
          v-if="showAddItemForm"
          :issuable-type="issuableType"
          :input-value="itemInputValue"
          :is-submitting="itemAddInProgress"
          :pending-references="pendingReferences"
          :auto-complete-sources="itemAutoCompleteSources"
          :path-id-separator="itemPathIdSeparator"
          @pendingIssuableRemoveRequest="handlePendingItemRemove"
          @addIssuableFormInput="handleAddItemFormInput"
          @addIssuableFormBlur="handleAddItemFormBlur"
          @addIssuableFormSubmit="handleAddItemFormSubmit"
          @addIssuableFormCancel="handleAddItemFormCancel"
        />
        <create-epic-form
          v-if="showCreateEpicForm"
          :is-submitting="itemCreateInProgress"
          @createEpicFormSubmit="handleCreateEpicFormSubmit"
          @createEpicFormCancel="handleCreateEpicFormCancel"
        />
        <create-issue-form
          v-if="isCreateIssueFormVisible && !showAddItemForm && !showCreateEpicForm"
          @cancel="isCreateIssueFormVisible = false"
        />
      </div>
      <related-items-tree-body
        v-if="!itemsFetchResultEmpty"
        :parent-item="parentItem"
        :children="directChildren"
      />
      <tree-item-remove-modal />
    </div>
  </div>
</template>

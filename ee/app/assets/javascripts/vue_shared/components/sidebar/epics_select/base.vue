<script>
import { mapState, mapGetters, mapActions } from 'vuex';

import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';

import { noneEpic } from 'ee/vue_shared/constants';

import createStore from './store';

import DropdownTitle from './dropdown_title.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';

import DropdownButton from './dropdown_button.vue';
import DropdownHeader from './dropdown_header.vue';
import DropdownSearchInput from './dropdown_search_input.vue';
import DropdownContents from './dropdown_contents.vue';

export default {
  store: createStore(),
  components: {
    GlLoadingIcon,
    DropdownTitle,
    DropdownValue,
    DropdownValueCollapsed,
    DropdownButton,
    DropdownHeader,
    DropdownSearchInput,
    DropdownContents,
  },
  props: {
    groupId: {
      type: Number,
      required: true,
    },
    issueId: {
      type: Number,
      required: true,
    },
    epicIssueId: {
      type: Number,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    blockTitle: {
      type: String,
      required: true,
    },
    initialEpic: {
      type: Object,
      required: true,
    },
    initialEpicLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      showDropdown: false,
    };
  },
  computed: {
    ...mapState(['epicSelectInProgress', 'epicsFetchInProgress', 'selectedEpic']),
    ...mapGetters(['groupEpics']),
    dropdownSelectInProgress() {
      return this.initialEpicLoading || this.epicSelectInProgress;
    },
  },
  watch: {
    /**
     * When Issue is created from Boards
     * Issue ID is updated post-render
     * so we need to watch it to update in state
     */
    issueId() {
      this.setIssueId(this.issueId);
    },
    /**
     * When Issues are selected within Boards
     * `initialEpic` gets updated to reflect
     * underlying selection.
     */
    initialEpic() {
      this.setSelectedEpic(this.initialEpic);
    },
    /**
     * Initial Epic is loaded via separate Sidebar store
     * So we need to watch for updates before updating local store.
     */
    initialEpicLoading() {
      this.setSelectedEpic(this.initialEpic);
    },
  },
  mounted() {
    this.setInitialData({
      groupId: this.groupId,
      issueId: this.issueId,
      selectedEpic: this.selectedEpic,
      selectedEpicIssueId: this.epicIssueId,
    });
    $(this.$refs.dropdown).on('shown.bs.dropdown', this.handleDropdownShown);
    $(this.$refs.dropdown).on('hidden.bs.dropdown', this.handleDropdownHidden);
  },
  methods: {
    ...mapActions([
      'setInitialData',
      'setIssueId',
      'setSearchQuery',
      'setSelectedEpic',
      'fetchEpics',
      'assignIssueToEpic',
      'removeIssueFromEpic',
    ]),
    handleEditClick() {
      this.showDropdown = true;

      // Wait for component to render dropdown container
      this.$nextTick(() => {
        // We're not calling $.dropdown('show') to open
        // dropdown and instead triggerring click on button
        // so that clicking outside can make dropdown close
        // additionally, this approach requires event trigger
        // to be deferred so that it doesn't close
        setTimeout(() => {
          $(this.$refs.dropdownButton.$el).trigger('click');
        });
      });
    },
    handleDropdownShown() {
      if (this.groupEpics.length === 0) this.fetchEpics();
    },
    handleDropdownHidden() {
      this.showDropdown = false;
    },
    handleItemSelect(epic) {
      if (epic.id === noneEpic.id && epic.title === noneEpic.title) {
        this.removeIssueFromEpic(this.selectedEpic);
      } else {
        this.assignIssueToEpic(epic);
      }
    },
  },
};
</script>

<template>
  <div class="block epic js-epic-block">
    <dropdown-value-collapsed :epic="selectedEpic" />
    <dropdown-title
      :can-edit="canEdit"
      :block-title="blockTitle"
      :is-loading="dropdownSelectInProgress"
      @onClickEdit="handleEditClick"
    />
    <dropdown-value v-show="!showDropdown" :epic="selectedEpic">
      <slot></slot>
    </dropdown-value>
    <div v-if="canEdit" v-show="showDropdown" class="epic-dropdown-container">
      <div ref="dropdown" class="dropdown">
        <dropdown-button ref="dropdownButton" />
        <div
          class="dropdown-menu dropdown-select
dropdown-menu-epics dropdown-menu-selectable"
        >
          <dropdown-header />
          <dropdown-search-input @onSearchInput="setSearchQuery" />
          <dropdown-contents
            v-if="!epicsFetchInProgress"
            :epics="groupEpics"
            :selected-epic="selectedEpic"
            @onItemSelect="handleItemSelect"
          />
          <gl-loading-icon
            v-if="epicsFetchInProgress"
            class="dropdown-contents-loading"
            size="md"
          />
        </div>
      </div>
    </div>
  </div>
</template>

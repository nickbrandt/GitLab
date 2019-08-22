<script>
import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';

import createFlash from '~/flash';
import { s__ } from '~/locale';
import { noneEpic } from 'ee/vue_shared/constants';

import EpicsSelectService from './service/epics_select_service';
import EpicsSelectStore from './store/epics_select_store';

import DropdownTitle from './dropdown_title.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';

import DropdownButton from './dropdown_button.vue';
import DropdownHeader from './dropdown_header.vue';
import DropdownSearchInput from './dropdown_search_input.vue';
import DropdownContents from './dropdown_contents.vue';

export default {
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
      service: new EpicsSelectService({
        groupId: this.groupId,
      }),
      store: new EpicsSelectStore({
        selectedEpic: this.initialEpic,
        groupId: this.groupId,
        selectedEpicIssueId: this.epicIssueId,
      }),
      showDropdown: false,
      isEpicSelectLoading: false,
      isEpicsLoading: false,
    };
  },
  computed: {
    epics() {
      return this.store.getEpics();
    },
    selectedEpic() {
      return this.store.getSelectedEpic();
    },
  },
  watch: {
    /**
     * Initial Epic is loaded via separate Sidebar store
     * So we need to watch for updates before updating local store.
     */
    initialEpicLoading() {
      this.store.setSelectedEpic(this.initialEpic);
    },
  },
  mounted() {
    $(this.$refs.dropdown).on('shown.bs.dropdown', this.handleDropdownShown);
    $(this.$refs.dropdown).on('hidden.bs.dropdown', this.handleDropdownHidden);
  },
  methods: {
    fetchGroupEpics() {
      this.isEpicsLoading = true;
      return this.service
        .getGroupEpics()
        .then(({ data }) => {
          this.isEpicsLoading = false;
          this.store.setEpics(data);
        })
        .catch(() => {
          this.isEpicsLoading = false;
          createFlash(s__('Epics|Something went wrong while fetching group epics.'));
        });
    },
    handleSelectSuccess({ data, epic, originalSelectedEpic }) {
      // Verify if attachment was successful
      this.isEpicSelectLoading = false;
      if (data.epic.id === epic.id && data.issue.id === this.issueId) {
        this.store.setSelectedEpicIssueId(data.id);
      } else {
        // Revert back to originally selected epic.
        this.store.setSelectedEpic(originalSelectedEpic);
      }
    },
    handleSelectFailure(errorMessage, originalSelectedEpic) {
      this.isEpicSelectLoading = false;
      // Revert back to originally selected epic in case of failure.
      this.store.setSelectedEpic(originalSelectedEpic);
      createFlash(errorMessage);
    },
    assignIssueToEpic(epic) {
      const originalSelectedEpic = this.store.getSelectedEpic();
      this.isEpicSelectLoading = true;

      this.store.setSelectedEpic(epic);
      return this.service
        .assignIssueToEpic(this.issueId, epic)
        .then(({ data }) => {
          this.handleSelectSuccess({ data, epic, originalSelectedEpic });
        })
        .catch(() => {
          this.handleSelectFailure(
            s__('Epics|Something went wrong while assigning issue to epic.'),
            originalSelectedEpic,
          );
        });
    },
    removeIssueFromEpic(epic) {
      const originalSelectedEpic = this.store.getSelectedEpic();
      this.isEpicSelectLoading = true;

      this.store.setSelectedEpic(noneEpic);
      return this.service
        .removeIssueFromEpic(this.store.getSelectedEpicIssueId(), epic)
        .then(({ data }) => {
          this.handleSelectSuccess({ data, epic, originalSelectedEpic });
        })
        .catch(() => {
          this.handleSelectFailure(
            s__('Epics|Something went wrong while removing issue from epic.'),
            originalSelectedEpic,
          );
        });
    },
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
      if (this.epics.length === 0) this.fetchGroupEpics();
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
    handleSearchInput(query) {
      this.store.filterEpics(query);
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
      :is-loading="initialEpicLoading || isEpicSelectLoading"
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
          <dropdown-search-input @onSearchInput="handleSearchInput" />
          <dropdown-contents
            v-if="!isEpicsLoading"
            :epics="epics"
            :selected-epic="selectedEpic"
            @onItemSelect="handleItemSelect"
          />
          <gl-loading-icon v-if="isEpicsLoading" class="dropdown-contents-loading" size="md" />
        </div>
      </div>
    </div>
  </div>
</template>

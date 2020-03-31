<script>
import { mapState, mapActions } from 'vuex';
import { debounce } from 'lodash';

import ListLabel from '../../models/label';

import LabelsSelectVue from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

export default {
  components: {
    LabelsSelectVue,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: true,
    },
    sidebarCollapsed: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      sidebarExpandedOnClick: false,
    };
  },
  computed: {
    ...mapState([
      'epicId',
      'labels',
      'namespace',
      'updateEndpoint',
      'labelsPath',
      'labelsWebUrl',
      'epicsWebUrl',
      'scopedLabels',
      'epicLabelsSelectInProgress',
    ]),
    epicContext() {
      return {
        labels: this.labels,
      };
    },
  },
  mounted() {
    document.addEventListener(
      'toggleSidebarRevealLabelsDropdown',
      this.toggleSidebarRevealLabelsDropdown,
    );
  },
  beforeDestroy() {
    document.removeEventListener(
      'toggleSidebarRevealLabelsDropdown',
      this.toggleSidebarRevealLabelsDropdown,
    );
  },
  methods: {
    ...mapActions(['toggleSidebar', 'updateEpicLabels']),
    toggleSidebarRevealLabelsDropdown() {
      const contentContainer = this.$el.closest('.page-with-contextual-sidebar');
      this.toggleSidebar({ sidebarCollapsed: this.sidebarCollapsed });
      // When sidebar is expanded, we need to wait
      // for rendering to finish before opening
      // dropdown as otherwise it causes `calc()`
      // used in CSS to miscalculate collapsed
      // sidebar size.
      debounce(() => {
        this.sidebarExpandedOnClick = true;
        if (this.canUpdate && contentContainer) {
          contentContainer
            .querySelector('.js-sidebar-dropdown-toggle')
            .dispatchEvent(new Event('click', { bubbles: true, cancelable: false }));
        }
      }, 100)();
    },
    handleDropdownClose() {
      if (this.sidebarExpandedOnClick) {
        this.sidebarExpandedOnClick = false;
        this.toggleSidebar({ sidebarCollapsed: this.sidebarCollapsed });
      }
    },
    handleLabelClick(label) {
      if (label.isAny) {
        this.epicContext.labels = [];
      } else {
        const labelIndex = this.epicContext.labels.findIndex(l => l.id === label.id);

        if (labelIndex === -1) {
          this.epicContext.labels.push(
            new ListLabel({
              id: label.id,
              title: label.title,
              color: label.color,
              textColor: label.text_color,
            }),
          );
        } else {
          this.epicContext.labels.splice(labelIndex, 1);
        }
      }
    },
    handleUpdateSelectedLabels(labels) {
      this.updateEpicLabels(labels);
    },
  },
};
</script>

<template>
  <labels-select-vue
    :allow-label-edit="canUpdate"
    :allow-label-create="true"
    :allow-multiselect="true"
    :allow-scoped-labels="scopedLabels"
    :selected-labels="labels"
    :labels-select-in-progress="epicLabelsSelectInProgress"
    :labels-fetch-path="labelsPath"
    :labels-manage-path="labelsWebUrl"
    :labels-filter-base-path="epicsWebUrl"
    variant="sidebar"
    class="block labels js-labels-block"
    @updateSelectedLabels="handleUpdateSelectedLabels"
    @onDropdownClose="handleDropdownClose"
    @toggleCollapse="toggleSidebarRevealLabelsDropdown"
    >{{ __('None') }}</labels-select-vue
  >
</template>

<script>
import { mapActions, mapState } from 'vuex';
import _ from 'underscore';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import IdeTree from './ide_tree.vue';
import RepoCommitSection from './repo_commit_section.vue';
import IdeReview from './ide_review.vue';
import SuccessMessage from './commit_sidebar/success_message.vue';
import IdeProjectHeader from './ide_project_header.vue';
import $ from 'jquery';

export default {
  components: {
    Icon,
    RepoCommitSection,
    IdeTree,
    IdeReview,
    SuccessMessage,
    IdeProjectHeader,
  },
  directives: {
    tooltip,
  },
  props: {
    tabs: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState(['currentActivityView']),
    shownTabs() {
      return this.tabs.filter(tab => tab.show);
    },
    tabViews() {
      return _.flatten(this.tabs.map(tab => tab.views));
    },
    aliveTabViews() {
      return this.tabViews.filter(view => this.isAliveView(view.name));
    },
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
    buttonClasses(tab) {
      return [this.isActiveTab(tab) ? 'active' : '', ...(tab.buttonClasses || [])];
    },
    clickTab(e, tab) {
      // TODO: These do not work, you must use JQuery and currentTarget
      // e.target.blur();
      // e.target.tooltip('hide');
      $(e.currentTarget).tooltip('hide');
      $(e.currentTarget).blur();

      this.updateActivityBarView(tab.views[0].name);
    },
    isActiveTab(tab) {
      return tab.views.some(view => this.isActiveView(view.name));
    },
    isAliveView(viewName) {
      // This will be replaced with a mapping to the isAliveView getter when this template is
      // refactored to use collapsible_sidebar.vue
      return this.currentActivityView === viewName;
    },
    isActiveView(viewName) {
      // This will be replaced with a mapping to the isActiveView getter when this template is
      // refactored to use collapsible_sidebar.vue
      return this.currentActivityView === viewName;
    },
  },
};
</script>

<template>
  <div
    data-qa-selector="ide_left_sidebar"
    class="multi-file-commit-panel ide-sidebar ide-left-sidebar flex-row-reverse min-height-0"
  >
    <div
      class="multi-file-commit-panel-inner d-flex flex-column align-items-stretch h-100 w-100 min-height-0"
    >
      <div
        v-for="tabView in aliveTabViews"
        v-show="isActiveView(tabView.name)"
        :key="tabView.name"
        :class="{ 'd-flex': isActiveView(tabView.name) }"
        class="js-tab-view flex-fill overflow-hidden min-height-0"
      >
        <component :is="tabView.component" />
      </div>
      <slot name="footer"></slot>
    </div>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li v-for="tab of shownTabs" :key="tab.title">
          <button
            v-tooltip
            :title="tab.title"
            :aria-label="tab.title"
            :class="buttonClasses(tab)"
            data-container="body"
            data-placement="right"
            :data-qa-selector="`${tab.title.toLowerCase()}_tab_button`"
            class="ide-sidebar-link"
            type="button"
            @click.prevent="clickTab($event, tab)"
          >
            <icon :size="16" :name="tab.icon" />
          </button>
        </li>
      </ul>
    </nav>
  </div>
</template>

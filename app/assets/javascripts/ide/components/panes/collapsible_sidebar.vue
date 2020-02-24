<script>
import { mapActions, mapState } from 'vuex';
import _ from 'underscore';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import ResizablePanel from '../resizable_panel.vue';
import { GlSkeletonLoading } from '@gitlab/ui';

export default {
  name: 'CollapsibleSidebar',
  directives: {
    tooltip,
  },
  components: {
    Icon,
    ResizablePanel,
    GlSkeletonLoading,
  },
  props: {
    extensionTabs: {
      type: Array,
      required: false,
      default: () => [],
    },
    side: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['loading']),
    ...mapState({
      isOpen(state) {
        return state[this.namespace].isOpen;
      },
      currentView(state) {
        return state[this.namespace].currentView;
      },
      isActiveView(state, getters) {
        return getters[`${this.namespace}/isActiveView`];
      },
      isAliveView(_state, getters) {
        return getters[`${this.namespace}/isAliveView`];
      },
    }),
    namespace() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `${this.side}Pane`;
    },
    tabs() {
      return this.extensionTabs.filter(tab => tab.show);
    },
    tabViews() {
      return _.flatten(this.tabs.map(tab => tab.views));
    },
    aliveTabViews() {
      return this.tabViews.filter(view => this.isAliveView(view.name));
    },
    otherSide() {
      return this.side === 'right' ? 'left' : 'right';
    },
  },
  methods: {
    ...mapActions({
      toggleOpen(dispatch) {
        return dispatch(`${this.namespace}/toggleOpen`);
      },
      open(dispatch, view) {
        return dispatch(`${this.namespace}/open`, view);
      },
    }),
    clickTab(e, tab) {
      e.target.blur();

      if (this.isActiveTab(tab)) {
        this.toggleOpen();
      } else {
        this.open(tab.views[0]);
      }
    },
    isActiveTab(tab) {
      return tab.views.some(view => this.isActiveView(view.name));
    },
    buttonClasses(tab) {
      return [
        this.side === 'right' ? 'is-right' : '',
        this.isActiveTab(tab) && this.isOpen ? 'active' : '',
        ...(tab.buttonClasses || []),
      ];
    },
  },
};
</script>

<template>
  <div
    :class="[`ide-${side}-sidebar`, { 'flex-row-reverse': side === 'left' }]"
    :data-qa-selector="`ide_${side}_sidebar`"
    class="multi-file-commit-panel ide-sidebar"
  >
    <div
      v-show="isOpen"
      :class="`ide-${side}-sidebar-${currentView}`"
      class="multi-file-commit-panel-inner"
    >
      <div class="h-100 d-flex flex-column align-items-stretch">
        <slot v-if="isOpen" name="header"></slot>
        <div
          v-for="tabView in aliveTabViews"
          v-show="isActiveView(tabView.name)"
          :key="tabView.name"
          class="flex-fill js-tab-view"
        >
          <slot :component="tabView.component">
            <component :is="tabView.component" />
          </slot>
        </div>
        <slot name="footer"></slot>
      </div>
    </div>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li>
          <slot name="header-icon"></slot>
        </li>
        <li v-for="tab of tabs" :key="tab.title">
          <button
            v-tooltip
            :title="tab.title"
            :aria-label="tab.title"
            :class="buttonClasses(tab)"
            data-container="body"
            :data-placement="otherSide"
            :data-qa-selector="`${tab.title.toLowerCase()}_tab_button`"
            class="ide-sidebar-link"
            type="button"
            @click="clickTab($event, tab)"
          >
            <icon :size="16" :name="tab.icon" />
          </button>
        </li>
      </ul>
    </nav>
  </div>
</template>

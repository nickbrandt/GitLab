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
    width: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      headerIsHovered: false,
    };
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
    buttonClassesAsObject(tab) {
      return _.chain(tab.buttonClasses)
        .object([])
        .mapObject(() => true)
        .value();
    },
    headerHoverClass() {
      return this.headerIsHovered ? 'ide-header-icon-highlight' : '';
    },
  },
};
</script>

<template>
  <div
    :class="`ide-${side}-sidebar`"
    :data-qa-selector="`ide_${side}_sidebar`"
    class="multi-file-commit-panel ide-sidebar"
  >
    <template v-if="loading">
      <resizable-panel :collapsible="false" :initial-width="width" :min-size="width" :side="side">
        <div class="multi-file-commit-panel-inner">
          <div v-for="n in 3" :key="n" class="multi-file-loading-container">
            <gl-skeleton-loading />
          </div>
        </div>
      </resizable-panel>
    </template>
    <template v-else>
      <resizable-panel
        v-for="tabView in aliveTabViews"
        v-show="isOpen && isActiveView(tabView.name)"
        :key="tabView.name"
        :collapsible="false"
        :initial-width="width"
        :min-size="width"
        :class="`ide-${side}-sidebar-${currentView}`"
        :side="side"
        class="multi-file-commit-panel-inner"
      >
        <div
          :class="headerHoverClass()"
          @mouseover="headerIsHovered = true"
          @mouseleave="headerIsHovered = false"
        >
          <slot v-if="isOpen" name="header"></slot>
        </div>
        <component :is="tabView.component" />
        <slot name="footer"></slot>
      </resizable-panel>
    </template>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li>
          <div
            :class="headerHoverClass()"
            @mouseover="headerIsHovered = true"
            @mouseleave="headerIsHovered = false"
          >
            <slot name="header-icon"></slot>
          </div>
        </li>
        <li v-for="tab of tabs" :key="tab.title">
          <button
            v-tooltip
            :title="tab.title"
            :aria-label="tab.title"
            :class="{
              'is-right': side === 'right',
              active: isActiveTab(tab) && isOpen,
              ...buttonClassesAsObject(tab),
            }"
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

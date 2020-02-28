<script>
import { mapActions, mapState } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import { GlSkeletonLoading } from '@gitlab/ui';
import $ from 'jquery';

export default {
  name: 'CollapsibleSidebar',
  directives: {
    tooltip,
  },
  components: {
    Icon,
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
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${this.side}Pane`;
    },
    tabs() {
      return this.extensionTabs.filter(tab => tab.show);
    },
    tabViews() {
      return this.tabs.map(tab => tab.views).flat();
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
      // TODO: These do not work, you must use JQuery and currentTarget
      // e.target.blur();
      // e.target.tooltip('hide');
      $(e.currentTarget).tooltip('hide');
      $(e.currentTarget).blur();

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
    :class="`ide-${side}-sidebar`"
    :data-qa-selector="`ide_${side}_sidebar`"
    class="multi-file-commit-panel ide-sidebar min-height-0"
  >
    <div
      v-show="isOpen"
      :class="[`ide-${side}-sidebar-${currentView}`, isOpen ? 'd-flex' : '']"
      class="multi-file-commit-panel-inner flex-column align-items-stretch h-100 w-100 min-height-0"
    >
      <div
        v-for="tabView in aliveTabViews"
        v-show="isActiveView(tabView.name)"
        :key="tabView.name"
        class="js-tab-view flex-fill min-height-0"
      >
        <component :is="tabView.component" />
      </div>
      <slot name="footer"></slot>
    </div>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
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
            @click.prevent="clickTab($event, tab)"
          >
            <icon :size="16" :name="tab.icon" />
          </button>
        </li>
      </ul>
    </nav>
  </div>
</template>

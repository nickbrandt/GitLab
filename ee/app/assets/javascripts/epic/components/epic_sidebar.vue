<script>
import { mapState, mapGetters, mapActions } from 'vuex';

import epicUtils from '../utils/epic_utils';

import SidebarHeader from './sidebar_items/sidebar_header.vue';
import SidebarTodo from './sidebar_items/sidebar_todo.vue';

export default {
  components: {
    SidebarHeader,
    SidebarTodo,
  },
  computed: {
    ...mapState(['sidebarCollapsed']),
    ...mapGetters(['isUserSignedIn']),
  },
  mounted() {
    this.toggleSidebarFlag(epicUtils.getCollapsedGutter());
  },
  methods: {
    ...mapActions(['toggleSidebarFlag']),
  },
};
</script>

<template>
  <aside
    :class="{
      'right-sidebar-expanded': !sidebarCollapsed,
      'right-sidebar-collapsed': sidebarCollapsed,
    }"
    :data-signed-in="isUserSignedIn"
    class="right-sidebar epic-sidebar"
  >
    <div class="issuable-sidebar js-issuable-update">
      <sidebar-header :sidebar-collapsed="sidebarCollapsed" />
      <sidebar-todo
        v-show="sidebarCollapsed && isUserSignedIn"
        :sidebar-collapsed="sidebarCollapsed"
      />
    </div>
  </aside>
</template>

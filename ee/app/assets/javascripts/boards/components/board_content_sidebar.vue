<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlDrawer } from '@gitlab/ui';
import { ISSUABLE } from '~/boards/constants';
import { contentTop } from '~/lib/utils/common_utils';

export default {
  headerHeight: `${contentTop()}px`,
  components: {
    GlDrawer,
  },
  computed: {
    ...mapGetters(['isSidebarOpen', 'getActiveIssue']),
    ...mapState(['sidebarType']),
    showSidebar() {
      return this.sidebarType === ISSUABLE;
    },
    issueTitle() {
      return this.getActiveIssue.title;
    },
  },
  methods: {
    ...mapActions(['unsetActiveId']),
  },
};
</script>

<template>
  <gl-drawer
    v-if="showSidebar"
    :open="isSidebarOpen"
    :header-height="$options.headerHeight"
    @close="unsetActiveId"
  >
    <template #header>
      <div data-testid="issue-title">
        <p class="gl-font-weight-bold">{{ issueTitle }}</p>
        <p class="gl-mb-0">{{ getActiveIssue.referencePath }}</p>
      </div>
    </template>
  </gl-drawer>
</template>

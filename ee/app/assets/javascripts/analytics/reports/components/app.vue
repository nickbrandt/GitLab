<script>
import { GlBreadcrumb, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

export default {
  name: 'ReportsApp',
  components: {
    GlBreadcrumb,
    GlIcon,
    GlLoadingIcon,
  },
  computed: {
    ...mapState('page', ['config', 'groupName', 'groupPath', 'isLoading']),
    breadcrumbs() {
      const {
        groupName = null,
        groupPath = null,
        config: { title },
      } = this;

      return [
        groupName && groupPath ? { text: groupName, href: `/${groupPath}` } : null,
        { text: title, href: '' },
      ].filter(Boolean);
    },
  },
  mounted() {
    this.fetchPageConfigData();
  },
  methods: {
    ...mapActions('page', ['fetchPageConfigData']),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-5" />
    <gl-breadcrumb v-else :items="breadcrumbs">
      <template #separator>
        <gl-icon name="angle-right" :size="8" />
      </template>
    </gl-breadcrumb>
  </div>
</template>

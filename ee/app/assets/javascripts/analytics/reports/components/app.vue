<script>
import { GlBreadcrumb, GlIcon } from '@gitlab/ui';
import { queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

export default {
  name: 'ReportsApp',
  components: {
    GlBreadcrumb,
    GlIcon,
  },
  methods: {
    breadcrumbs() {
      const { groupName = null, groupPath = null } = queryToObject(document.location.search);

      return [
        groupName && groupPath ? { text: groupName, href: `/${groupPath}` } : null,
        { text: s__('GenericReports|Report'), href: '' },
      ].filter(Boolean);
    },
  },
};
</script>
<template>
  <div>
    <gl-breadcrumb :items="breadcrumbs()">
      <template #separator>
        <gl-icon name="angle-right" :size="8" />
      </template>
    </gl-breadcrumb>
  </div>
</template>

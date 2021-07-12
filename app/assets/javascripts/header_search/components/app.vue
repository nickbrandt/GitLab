<script>
import { GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'HeaderSearchApp',
  i18n: {
    searchPlaceholder: __('Search or jump to...'),
  },
  components: {
    GlDropdown,
    GlSearchBoxByType,
  },
};
</script>

<template>
  <gl-dropdown toggle-class="header-search gl-p-0!">
    <template #button-content>
      <gl-search-box-by-type :placeholder="$options.i18n.searchPlaceholder" />
    </template>
  </gl-dropdown>
</template>

<script>
import { GlIcon } from '@gitlab/ui';

export default {
  name: 'EmployeeBadge',
  components: { GlIcon },
};
</script>

<template>
  <span class="gl-text-gray-700 text-nowrap">
    <gl-icon name="work" :size="16" class="align-middle" />
    <!-- `GitLab` does not need to be translated -->
    <!-- eslint-disable-next-line @gitlab/vue-i18n/no-bare-strings -->
    <span class="align-middle">GitLab</span>
  </span>
</template>

<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';

export default {
  name: 'EmployeeBadge',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlIcon },
};
</script>

<template>
  <gl-icon
    v-gl-tooltip.hover
    :title="__('GitLab Employee')"
    name="tanuki-verified"
    class="gl-text-purple d-inline-block align-middle"
  />
</template>

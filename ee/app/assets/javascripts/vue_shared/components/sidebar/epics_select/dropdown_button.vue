<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
};
</script>

<template>
  <button
    type="button"
    class="dropdown-menu-toggle js-epic-select js-extra-options"
    data-display="static"
    data-toggle="dropdown"
  >
    <span class="dropdown-toggle-text">{{ __('Epic') }}</span>
    <icon name="chevron-down" />
  </button>
</template>

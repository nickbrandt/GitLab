<script>
import { mapActions } from 'vuex';
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  methods: {
    ...mapActions(['openDrawer']),
  },
};
</script>

<template>
  <li>
    <gl-link @click="openDrawer">{{ __("See what's new at GitLab") }}</gl-link>
  </li>
</template>

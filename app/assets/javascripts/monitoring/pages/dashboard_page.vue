<script>
import Dashboard from '../components/dashboard.vue';

export default {
  components: {
    Dashboard,
  },
};
</script>
<template>
  <dashboard v-bind="{ ...this.$attrs.dashboardProps }" />
</template>

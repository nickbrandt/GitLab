<script>
export default {
  name: 'JiraConnectApp',
  props: {
    namespacesEndpoint: {
      type: String,
      required: true,
    },
  },
  computed: {
    state() {
      return this.$root.$data.state || {};
    },
    error() {
      return this.state.error;
    },
  },
};
</script>

<template>
  <div></div>
</template>

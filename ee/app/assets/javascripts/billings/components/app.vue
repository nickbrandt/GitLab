<script>
import { mapActions } from 'vuex';
import SubscriptionTable from './subscription_table.vue';

export default {
  name: 'SubscriptionApp',
  components: {
    SubscriptionTable,
  },
  props: {
    namespaceId: {
      type: String,
      required: false,
      default: null,
    },
  },
  created() {
    this.setNamespaceId(this.namespaceId);
  },
  methods: {
    ...mapActions('subscription', ['setNamespaceId']),
  },
};
</script>

<template>
  <subscription-table />
</template>

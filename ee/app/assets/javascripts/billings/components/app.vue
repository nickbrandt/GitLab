<script>
import { mapActions } from 'vuex';
import SubscriptionTable from './subscription_table.vue';

export default {
  name: 'SubscriptionApp',
  components: {
    SubscriptionTable,
  },
  props: {
    planUpgradeHref: {
      type: String,
      required: false,
      default: null,
    },
    namespaceId: {
      type: String,
      required: false,
      default: null,
    },
    namespaceName: {
      type: String,
      required: true,
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
  <subscription-table :namespace-name="namespaceName" :plan-upgrade-href="planUpgradeHref" />
</template>

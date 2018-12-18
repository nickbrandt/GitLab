<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import ApprovalRulesEmpty from './approval_rules_empty.vue';

export default {
  components: {
    GlLoadingIcon,
    ApprovalRulesEmpty,
  },
  computed: {
    ...mapState(['isLoading', 'rules']),
    isEmpty() {
      return !this.rules || !this.rules.length;
    },
  },
  created() {
    this.fetchRules();
  },
  methods: {
    ...mapActions(['fetchRules']),
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" :size="2" />
  <approval-rules-empty v-else-if="isEmpty" />
</template>

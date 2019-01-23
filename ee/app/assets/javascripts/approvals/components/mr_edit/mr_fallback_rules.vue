<script>
import { mapState, mapActions } from 'vuex';
import FallbackRules from '../fallback_rules.vue';

export default {
  components: {
    FallbackRules,
  },
  computed: {
    ...mapState(['settings']),
  },
  methods: {
    ...mapActions(['putFallbackRule']),
  },
};
</script>

<template>
  <fallback-rules>
    <input
      slot="approvals-required"
      slot-scope="{ approvalsRequired }"
      :value="approvalsRequired"
      :disabled="!settings.canEdit"
      class="form-control mw-6em"
      type="number"
      min="0"
      @input="putFallbackRule({ approvalsRequired: $event.target.value })"
    />
  </fallback-rules>
</template>

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
  <fallback-rules :has-controls="settings.canEdit">
    <input
      slot="approvals-required"
      slot-scope="{ approvalsRequired, minApprovalsRequired }"
      :value="approvalsRequired"
      :disabled="!settings.canEdit"
      class="form-control mw-6em"
      type="number"
      :min="minApprovalsRequired"
      @input="putFallbackRule({ approvalsRequired: Number($event.target.value) })"
    />
  </fallback-rules>
</template>

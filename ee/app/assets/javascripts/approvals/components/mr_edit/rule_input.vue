<script>
import { mapState, mapActions } from 'vuex';
import { RULE_TYPE_ANY_APPROVER } from '../../constants';

const ANY_RULE_NAME = 'All Members';

export default {
  props: {
    rule: {
      type: Object,
      required: true,
    },
    isMrEdit: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    ...mapState(['settings']),
  },
  methods: {
    ...mapActions(['putRule', 'postRule']),
    onInputChange(event) {
      if (this.rule.id) {
        this.putRule({ id: this.rule.id, approvalsRequired: Number(event.target.value) });
      } else {
        this.postRule({
          name: ANY_RULE_NAME,
          ruleType: RULE_TYPE_ANY_APPROVER,
          approvalsRequired: Number(event.target.value),
        });
      }
    },
  },
};
</script>

<template>
  <input
    :value="rule.approvalsRequired"
    :disabled="!settings.canEdit"
    class="form-control mw-6em"
    type="number"
    :min="rule.minApprovalsRequired || 0"
    @input="onInputChange"
  />
</template>

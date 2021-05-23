<script>
import { GlFormInput, GlDropdown, GlDropdownItem, GlCard, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ACTIONS, ALERT_STATUSES } from '../constants';

export const i18n = {
  fields: {
    rules: {
      condition: s__('EscalationPolicies|IF alert is not %{alertStatus} in %{minutes} minutes'),
      action: s__('EscalationPolicies|THEN %{doAction} %{schedule}'),
      selectSchedule: s__('EscalationPolicies|Select schedule'),
    },
  },
};

export default {
  i18n,
  ALERT_STATUSES,
  ACTIONS,
  components: {
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    GlCard,
    GlSprintf,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    schedules: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <gl-card class="gl-border-gray-400 gl-bg-gray-10 gl-mb-3">
    <div class="gl-display-flex gl-align-items-center">
      <gl-sprintf :message="$options.i18n.fields.rules.condition">
        <template #alertStatus>
          <gl-dropdown
            class="rule-control gl-mx-3"
            :text="$options.ALERT_STATUSES[rule.status]"
            data-testid="alert-status-dropdown"
          >
            <gl-dropdown-item
              v-for="(label, status) in $options.ALERT_STATUSES"
              :key="status"
              :is-checked="rule.status === status"
              is-check-item
            >
              {{ label }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>
        <template #minutes>
          <gl-form-input class="gl-mx-3 rule-elapsed-minutes" :value="0" />
        </template>
      </gl-sprintf>
    </div>
    <div class="gl-display-flex gl-align-items-center gl-mt-3">
      <gl-sprintf :message="$options.i18n.fields.rules.action">
        <template #doAction>
          <gl-dropdown
            class="rule-control gl-mx-3"
            :text="$options.ACTIONS[rule.action]"
            data-testid="action-dropdown"
          >
            <gl-dropdown-item
              v-for="(label, action) in $options.ACTIONS"
              :key="action"
              :is-checked="rule.action === action"
              is-check-item
            >
              {{ label }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>
        <template #schedule>
          <gl-dropdown
            class="rule-control gl-mx-3"
            :text="$options.i18n.fields.rules.selectSchedule"
            data-testid="schedules-dropdown"
          >
            <gl-dropdown-item v-for="schedule in schedules" :key="schedule.id" is-check-item>
              {{ schedule.name }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>
      </gl-sprintf>
    </div>
  </gl-card>
</template>

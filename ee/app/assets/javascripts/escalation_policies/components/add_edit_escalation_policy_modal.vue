<script>
import { GlModal } from '@gitlab/ui';
import { set } from 'lodash';
import { s__, __ } from '~/locale';
import { addEscalationPolicyModalId } from '../constants';
import { isNameFieldValid } from '../utils';
import AddEditEscalationPolicyForm from './add_edit_escalation_policy_form.vue';

export const i18n = {
  cancel: __('Cancel'),
  addEscalationPolicy: s__('EscalationPolicies|Add escalation policy'),
  editEscalationPolicy: s__('EscalationPolicies|Edit escalation policy'),
};

export default {
  i18n,
  addEscalationPolicyModalId,
  components: {
    GlModal,
    AddEditEscalationPolicyForm,
  },
  props: {
    escalationPolicy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      loading: false,
      form: {
        name: this.escalationPolicy.name,
        description: this.escalationPolicy.description,
      },
      validationState: {
        name: true,
        rules: true,
      },
    };
  },
  computed: {
    actionsProps() {
      return {
        primary: {
          text: i18n.addEscalationPolicy,
          attributes: [
            { variant: 'info' },
            { loading: this.loading },
            { disabled: !this.isFormValid },
          ],
        },
        cancel: {
          text: i18n.cancel,
        },
      };
    },
    isFormValid() {
      return Object.values(this.validationState).every(Boolean);
    },
  },
  methods: {
    updateForm({ field, value }) {
      set(this.form, field, value);
      this.validateForm(field);
    },
    validateForm(field) {
      if (field === 'name') {
        this.validationState.name = isNameFieldValid(this.form.name);
      }
    },
  },
};
</script>

<template>
  <gl-modal
    class="escalation-policy-modal"
    :modal-id="$options.addEscalationPolicyModalId"
    :title="$options.i18n.addEscalationPolicy"
    :action-primary="actionsProps.primary"
    :action-cancel="actionsProps.cancel"
  >
    <add-edit-escalation-policy-form
      :validation-state="validationState"
      :form="form"
      @update-escalation-policy-form="updateForm"
    />
  </gl-modal>
</template>

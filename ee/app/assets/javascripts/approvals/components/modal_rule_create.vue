<script>
import { mapState } from 'vuex';
import { __ } from '~/locale';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';
import RuleForm from './rule_form.vue';

export default {
  components: {
    GlModalVuex,
    RuleForm,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    isMrEdit: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  computed: {
    ...mapState('createModal', {
      rule(state) {
        /*
         * rule-form component expects undefined if we pre-populate the form input,
         * otherwise populate with existing rule
         */
        return state.data?.initRuleField ? undefined : state.data;
      },
      originalData: 'data',
    }),
    initRuleFieldName() {
      return this.originalData?.initRuleField && this.originalData?.name
        ? this.originalData.name
        : '';
    },
    title() {
      return this.rule ? __('Update approval rule') : __('Add approval rule');
    },
  },
  methods: {
    submit() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal-vuex
    modal-module="createModal"
    :modal-id="modalId"
    :title="title"
    :ok-title="title"
    ok-variant="success"
    :cancel-title="__('Cancel')"
    size="sm"
    @ok.prevent="submit"
  >
    <rule-form
      ref="form"
      :init-rule="rule"
      :is-mr-edit="isMrEdit"
      :init-rule-field-name="initRuleFieldName"
    />
  </gl-modal-vuex>
</template>

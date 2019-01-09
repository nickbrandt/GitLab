<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import ModalRuleCreate from './modal_rule_create.vue';
import ModalRuleRemove from './modal_rule_remove.vue';
import RulesEmpty from './rules_empty.vue';

const CREATE_MODAL_ID = 'approvals-settings-create-modal';
const REMOVE_MODAL_ID = 'approvals-settings-remove-modal';

export default {
  components: {
    ModalRuleCreate,
    ModalRuleRemove,
    RulesEmpty,
    GlButton,
    GlLoadingIcon,
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
    ...mapActions({ openCreateModal: 'createModal/open' }),
  },
  CREATE_MODAL_ID,
  REMOVE_MODAL_ID,
};
</script>

<template>
  <div>
    <template v-if="isEmpty">
      <gl-loading-icon v-if="isLoading" :size="2" />
      <rules-empty v-else @click="openCreateModal(null);" />
    </template>
    <template v-else>
      <slot name="rules" v-bind:rules="rules"> </slot>
      <div class="border-top border-bottom py-3 px-2">
        <gl-loading-icon v-if="isLoading" />
        <div class="d-flex">
          <gl-button class="ml-auto btn-info btn-inverted" @click="openCreateModal(null);">{{
            __('Add approvers')
          }}</gl-button>
        </div>
      </div>
    </template>
    <modal-rule-create :modal-id="$options.CREATE_MODAL_ID" />
    <modal-rule-remove :modal-id="$options.REMOVE_MODAL_ID" />
  </div>
</template>

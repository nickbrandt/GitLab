<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import ModalRuleCreate from './modal_rule_create.vue';
import ModalRuleRemove from './modal_rule_remove.vue';
import RulesEmpty from './rules_empty.vue';

export default {
  components: {
    ModalRuleCreate,
    ModalRuleRemove,
    RulesEmpty,
    GlButton,
    GlLoadingIcon,
  },
  computed: {
    ...mapState({
      settings: 'settings',
      isLoading: state => state.approvals.isLoading,
    }),
    ...mapGetters(['isEmpty']),
    createModalId() {
      return `${this.settings.prefix}-approvals-create-modal`;
    },
    removeModalId() {
      return `${this.settings.prefix}-approvals-remove-modal`;
    },
  },
  created() {
    this.fetchRules();
  },
  methods: {
    ...mapActions(['fetchRules']),
    ...mapActions({ openCreateModal: 'createModal/open' }),
  },
};
</script>

<template>
  <div>
    <template v-if="isEmpty">
      <gl-loading-icon v-if="isLoading" :size="2" />
      <rules-empty v-else @click="openCreateModal(null);" />
    </template>
    <template v-else>
      <div class="border-bottom"><slot name="rules"></slot></div>
      <div v-if="settings.canEdit" class="border-bottom py-3 px-2">
        <gl-loading-icon v-if="isLoading" />
        <div class="d-flex">
          <gl-button class="ml-auto btn-info btn-inverted" @click="openCreateModal(null);">{{
            __('Add approvers')
          }}</gl-button>
        </div>
      </div>
    </template>
    <slot name="footer"></slot>
    <modal-rule-create :modal-id="createModalId" />
    <modal-rule-remove :modal-id="removeModalId" />
  </div>
</template>

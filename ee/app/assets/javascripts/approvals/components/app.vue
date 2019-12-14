<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import ModalRuleCreate from './modal_rule_create.vue';
import ModalRuleRemove from './modal_rule_remove.vue';

export default {
  components: {
    ModalRuleCreate,
    ModalRuleRemove,
    GlButton,
    GlLoadingIcon,
  },
  computed: {
    ...mapState({
      settings: 'settings',
      isLoading: state => state.approvals.isLoading,
      hasLoaded: state => state.approvals.hasLoaded,
    }),
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
  <div class="js-approval-rules">
    <gl-loading-icon v-if="!hasLoaded" :size="2" />
    <template v-else>
      <div class="border-bottom">
        <slot name="rules"></slot>
      </div>
      <div v-if="settings.canEdit && settings.allowMultiRule" class="border-bottom py-3 px-2">
        <gl-loading-icon v-if="isLoading" />
        <div v-if="settings.allowMultiRule" class="d-flex">
          <gl-button
            class="ml-auto btn-info btn-inverted"
            data-qa-selector="add_approvers_button"
            @click="openCreateModal(null)"
          >
            {{ __('Add approval rule') }}
          </gl-button>
        </div>
      </div>
      <slot name="footer"></slot>
    </template>
    <modal-rule-create :modal-id="createModalId" />
    <modal-rule-remove :modal-id="removeModalId" />
  </div>
</template>

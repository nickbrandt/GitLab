<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import ModalRuleCreate from './modal_rule_create.vue';
import ModalRuleRemove from './modal_rule_remove.vue';
import FallbackRules from './fallback_rules.vue';

export default {
  components: {
    ModalRuleCreate,
    ModalRuleRemove,
    GlButton,
    GlLoadingIcon,
    FallbackRules,
  },
  computed: {
    ...mapState({
      settings: 'settings',
      isLoading: state => state.approvals.isLoading,
      hasLoaded: state => state.approvals.hasLoaded,
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
    <gl-loading-icon v-if="!hasLoaded" :size="2" />
    <template v-else>
      <div class="border-bottom">
        <slot v-if="isEmpty" name="fallback"> <fallback-rules /> </slot>
        <slot v-else name="rules"></slot>
      </div>
      <div v-if="settings.canEdit" class="border-bottom py-3 px-2">
        <gl-loading-icon v-if="isLoading" />
        <div v-if="settings.allowMultiRule" class="d-flex">
          <gl-button class="ml-auto btn-info btn-inverted" @click="openCreateModal(null)">{{
            __('Add approvers')
          }}</gl-button>
        </div>
      </div>
      <slot name="footer"></slot>
    </template>
    <modal-rule-create :modal-id="createModalId" />
    <modal-rule-remove :modal-id="removeModalId" />
  </div>
</template>

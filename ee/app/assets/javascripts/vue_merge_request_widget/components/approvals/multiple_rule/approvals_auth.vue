<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  props: {
    isApproving: {
      type: Boolean,
      default: false,
      required: false,
    },
    hasError: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      approvalPassword: '',
    };
  },
  mounted() {
    this.$nextTick(() => this.$refs.approvalPassword.focus());
  },
  methods: {
    approve() {
      this.$emit('approve', this.approvalPassword);
    },
    cancel() {
      this.$emit('cancel');
    },
  },
};
</script>
<template>
  <form class="form-inline align-items-center" @submit.prevent="approve">
    <div class="form-group mb-2 mr-2 mb-sm-0">
      <input
        ref="approvalPassword"
        v-model="approvalPassword"
        type="password"
        class="form-control"
        :class="{ 'is-invalid': hasError }"
        autocomplete="new-password"
        :placeholder="s__('Password')"
      />
    </div>
    <div class="form-group mb-2 mr-2 mb-sm-0">
      <gl-button
        variant="primary"
        :disabled="isApproving"
        size="sm"
        class="mr-1 js-confirm"
        @click="approve"
      >
        <gl-loading-icon v-if="isApproving" inline />
        {{ s__('Confirm') }}
      </gl-button>
      <gl-button
        variant="default"
        :disabled="isApproving"
        size="sm"
        class="js-cancel"
        @click="cancel"
      >
        {{ s__('Cancel') }}
      </gl-button>
    </div>
    <div v-if="hasError">
      <span class="gl-field-error">
        {{ s__('mrWidget|Approval password is invalid.') }}
      </span>
    </div>
  </form>
</template>

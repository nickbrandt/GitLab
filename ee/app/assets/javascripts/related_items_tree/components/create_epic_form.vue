<script>
import { GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  components: {
    GlDeprecatedButton,
    GlLoadingIcon,
  },
  props: {
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      inputValue: '',
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      return this.inputValue.length === 0 || this.isSubmitting;
    },
    buttonLabel() {
      return this.isSubmitting ? __('Creating epic') : __('Create epic');
    },
  },
  mounted() {
    this.$nextTick()
      .then(() => {
        this.$refs.input.focus();
      })
      .catch(() => {});
  },
  methods: {
    onFormSubmit() {
      this.$emit('createEpicFormSubmit', this.inputValue.trim());
    },
    onFormCancel() {
      this.$emit('createEpicFormCancel');
    },
  },
};
</script>

<template>
  <form @submit.prevent="onFormSubmit">
    <input
      ref="input"
      v-model="inputValue"
      :placeholder="__('New epic title')"
      type="text"
      class="form-control"
      @keyup.escape.exact="onFormCancel"
    />
    <div class="add-issuable-form-actions clearfix">
      <gl-deprecated-button
        :disabled="isSubmitButtonDisabled"
        variant="success"
        type="submit"
        class="float-left"
      >
        {{ buttonLabel }}
        <gl-loading-icon v-if="isSubmitting" :inline="true" />
      </gl-deprecated-button>
      <gl-deprecated-button class="float-right" @click="onFormCancel">{{
        __('Cancel')
      }}</gl-deprecated-button>
    </div>
  </form>
</template>

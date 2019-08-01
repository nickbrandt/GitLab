<script>
import { GlLoadingIcon } from '@gitlab/ui';
import RelatedIssuableInput from './related_issuable_input.vue';
import { issuableTypesMap } from '../constants';

export default {
  name: 'AddIssuableForm',
  components: {
    GlLoadingIcon,
    RelatedIssuableInput,
  },
  props: {
    inputValue: {
      type: String,
      required: true,
    },
    pendingReferences: {
      type: Array,
      required: false,
      default: () => [],
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: issuableTypesMap.ISSUE,
    },
  },
  computed: {
    isSubmitButtonDisabled() {
      return (
        (this.inputValue.length === 0 && this.pendingReferences.length === 0) || this.isSubmitting
      );
    },
  },
  methods: {
    onPendingIssuableRemoveRequest(params) {
      this.$emit('pendingIssuableRemoveRequest', params);
    },
    onFormSubmit() {
      this.$emit('addIssuableFormSubmit', this.$refs.relatedIssuableInput.$refs.input.value);
    },
    onFormCancel() {
      this.$emit('addIssuableFormCancel');
    },
    onAddIssuableFormInput(params) {
      this.$emit('addIssuableFormInput', params);
    },
    onAddIssuableFormBlur(params) {
      this.$emit('addIssuableFormBlur', params);
    },
  },
};
</script>

<template>
  <form @submit.prevent="onFormSubmit">
    <related-issuable-input
      ref="relatedIssuableInput"
      :focus-on-mount="true"
      :references="pendingReferences"
      :path-id-separator="pathIdSeparator"
      :input-value="inputValue"
      :auto-complete-sources="autoCompleteSources"
      :auto-complete-options="{ issues: true, epics: true }"
      :issuable-type="issuableType"
      @pendingIssuableRemoveRequest="onPendingIssuableRemoveRequest"
      @formCancel="onFormCancel"
      @addIssuableFormBlur="onAddIssuableFormBlur"
      @addIssuableFormInput="onAddIssuableFormInput"
    />
    <div class="add-issuable-form-actions clearfix">
      <button
        ref="addButton"
        :disabled="isSubmitButtonDisabled"
        type="submit"
        class="js-add-issuable-form-add-button btn btn-success float-left qa-add-issue-button"
      >
        Add
        <gl-loading-icon v-if="isSubmitting" ref="loadingIcon" :inline="true" />
      </button>
      <button type="button" class="btn btn-default float-right" @click="onFormCancel">
        {{ __('Cancel') }}
      </button>
    </div>
  </form>
</template>

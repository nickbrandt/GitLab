<script>
import $ from 'jquery';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import { GlLoadingIcon } from '@gitlab/ui';
import issueToken from './issue_token.vue';
import { autoCompleteTextMap, inputPlaceholderTextMap } from '../constants';

const SPACE_FACTOR = 1;

export default {
  name: 'AddIssuableForm',
  components: {
    issueToken,
    GlLoadingIcon,
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
      default: 'issue',
    },
  },

  data() {
    return {
      isInputFocused: false,
      isAutoCompleteOpen: false,
    };
  },

  computed: {
    inputPlaceholder() {
      const { issuableType, allowAutoComplete } = this;
      const allowAutoCompleteText = autoCompleteTextMap[allowAutoComplete][issuableType];
      return `${inputPlaceholderTextMap[issuableType]}${allowAutoCompleteText}`;
    },
    isSubmitButtonDisabled() {
      return (
        (this.inputValue.length === 0 && this.pendingReferences.length === 0) || this.isSubmitting
      );
    },
    allowAutoComplete() {
      return Object.keys(this.autoCompleteSources).length > 0;
    },
  },

  mounted() {
    const $input = $(this.$refs.input);
    if (this.allowAutoComplete) {
      this.gfmAutoComplete = new GfmAutoComplete(this.autoCompleteSources);
      this.gfmAutoComplete.setup($input, {
        issues: true,
        epics: true,
      });
      $input.on('shown-issues.atwho', this.onAutoCompleteToggled.bind(this, true));
      $input.on('hidden-issues.atwho', this.onAutoCompleteToggled.bind(this, false));
    }

    this.$refs.input.focus();
  },

  beforeDestroy() {
    const $input = $(this.$refs.input);
    $input.off('shown-issues.atwho');
    $input.off('hidden-issues.atwho');
    $input.off('inserted-issues.atwho', this.onInput);
  },

  methods: {
    onInput() {
      const { value } = this.$refs.input;
      const caretPos = $(this.$refs.input).caret('pos');
      const rawRefs = value.split(/\s/);
      let touchedReference;
      let position = 0;

      const untouchedRawRefs = rawRefs
        .filter(ref => {
          let isTouched = false;
          if (caretPos >= position && caretPos <= position + ref.length) {
            touchedReference = ref;
            isTouched = true;
          }

          // `+ SPACE_FACTOR` to factor in the missing space we split at earlier
          position = position + ref.length + SPACE_FACTOR;

          return !isTouched;
        })
        .filter(ref => ref.trim().length > 0);

      this.$emit('addIssuableFormInput', {
        newValue: value,
        untouchedRawReferences: untouchedRawRefs,
        touchedReference,
        caretPos,
      });
    },
    onFocus() {
      this.isInputFocused = true;
    },
    onBlur() {
      this.isInputFocused = false;

      // Avoid tokenizing partial input when clicking an autocomplete item
      if (!this.isAutoCompleteOpen) {
        const { value } = this.$refs.input;
        this.$emit('addIssuableFormBlur', value);
      }
    },
    onAutoCompleteToggled(isOpen) {
      this.isAutoCompleteOpen = isOpen;
    },
    onInputWrapperClick() {
      this.$refs.input.focus();
    },
    onPendingIssuableRemoveRequest(params) {
      this.$emit('pendingIssuableRemoveRequest', params);
    },
    onFormSubmit() {
      const { value } = this.$refs.input;
      this.$emit('addIssuableFormSubmit', value);
    },
    onFormCancel() {
      this.$emit('addIssuableFormCancel');
    },
  },
};
</script>

<template>
  <form @submit.prevent="onFormSubmit">
    <div
      ref="issuableFormWrapper"
      :class="{ focus: isInputFocused }"
      class="add-issuable-form-input-wrapper form-control"
      role="button"
      @click="onInputWrapperClick"
    >
      <ul class="add-issuable-form-input-token-list">
        <!--
          We need to ensure this key changes any time the pendingReferences array is updated
          else two consecutive pending ref strings in an array with the same name will collide
          and cause odd behavior when one is removed.
        -->
        <li
          v-for="(reference, index) in pendingReferences"
          :key="`related-issues-token-${reference}`"
          class="js-add-issuable-form-token-list-item add-issuable-form-token-list-item"
        >
          <issue-token
            :id-key="index"
            :display-reference="reference"
            :can-remove="true"
            :is-condensed="true"
            :path-id-separator="pathIdSeparator"
            event-namespace="pendingIssuable"
            @pendingIssuableRemoveRequest="onPendingIssuableRemoveRequest"
          />
        </li>
        <li class="add-issuable-form-input-list-item">
          <input
            ref="input"
            :value="inputValue"
            :placeholder="inputPlaceholder"
            type="text"
            class="js-add-issuable-form-input add-issuable-form-input qa-add-issue-input"
            @input="onInput"
            @focus="onFocus"
            @blur="onBlur"
            @keyup.escape.exact="onFormCancel"
          />
        </li>
      </ul>
    </div>
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
        Cancel
      </button>
    </div>
  </form>
</template>

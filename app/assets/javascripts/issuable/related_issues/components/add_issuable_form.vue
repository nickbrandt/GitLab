<script>
import eventHub from '../event_hub';
import IssueToken from './issue_token.vue';
import GfmAutoComplete from '../../../gfm_auto_complete';

export default {
  name: 'AddIssuableForm',

  props: {
    inputValue: {
      type: String,
      required: true,
    },
    addButtonLabel: {
      type: String,
      required: true,
    },
    pendingIssuables: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  components: {
    issueToken: IssueToken,
  },

  methods: {
    onInput() {
      const value = this.$refs.input.value;
      eventHub.$emit('addIssuableFormInput', value, $(this.$refs.input).caret('pos'));
    },
    onBlur() {
      const value = this.$refs.input.value;
      eventHub.$emit('addIssuableFormBlur', value);
    },
    onInputWrapperClick() {
      this.$refs.input.focus();
    },
    onPendingIssuableRemoveRequest(reference) {
      eventHub.$emit('addIssuableFormIssuableRemoveRequest', reference);
    },
    onIssuableSubmit() {
      eventHub.$emit('addIssuableFormSubmit');
    },
    addIssuableFormCancel() {
      eventHub.$emit('addIssuableFormCancel');
    },
  },

  mounted() {
    const $input = $(this.$refs.input);
    new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources).setup($input, {
      issues: true,
    });
    $input.on('inserted-issues.atwho', () => {
      this.onInput();
    });
  },
};
</script>

<template>
  <div>
    <div
      class="add-issuable-form-input-wrapper form-control"
      @click="onInputWrapperClick">
      <ul class="add-issuable-form-input-token-list">
        <li
          v-for="issuable in pendingIssuables"
          class="add-issuable-form-input-token-list-item">
          <issueToken
            :reference="issuable.reference"
            :title="issuable.title"
            :path="issuable.path"
            :state="issuable.state"
            canRemove
            @removeRequest="onPendingIssuableRemoveRequest(issuable.reference)" />
        </li>
        <li class="add-issuable-form-input-token-list-input-item">
          <input
            ref="input"
            type="text"
            class="add-issuable-form-input"
            :value="inputValue"
            placeholder="Search issues..."
            @input="onInput"
            @blur="onBlur" />
        </li>
      </ul>
    </div>
    <div class="clearfix prepend-top-10">
      <button
        class="btn btn-new pull-left"
        @click="onIssuableSubmit">
        {{ addButtonLabel }}
      </button>
      <button
        class="btn btn-default pull-right"
        @click="addIssuableFormCancel">
        Cancel
      </button>
    </div>
  </div>
</template>

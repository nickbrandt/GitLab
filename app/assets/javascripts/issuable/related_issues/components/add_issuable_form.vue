<script>
import eventHub from '../event_hub';
import IssueToken from './issue_token.vue';
import GfmAutoComplete from '../../../gfm_auto_complete';

export default {
  name: 'AddIssuableForm',

  props: {
    inputValue: {
      type: String,
      required: false,
      default: '',
    },
    pendingIssuables: {
      type: Array,
      required: false,
      default: [],
    },
    addButtonLabel: {
      type: String,
      required: true,
    },
  },

  components: {
    issueToken: IssueToken,
  },

  methods: {
    onInput() {
      const value = this.$refs.input.value;
      eventHub.$emit('addIssuableFormInput', value);
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
    <div class="add-issuable-form-input-wrapper form-control">
      <ul class="add-issuable-form-input-token-list">
        <li v-for="issuable in pendingIssuables">
          <issueToken
            :reference="issuable.reference"
            :title="issuable.title"
            :path="issuable.path"
            :state="issuable.state" />
        </li>
      </ul>
      <input
        ref="input"
        type="text"
        class="add-issuable-form-input"
        :value="inputValue"
        placeholder="Search issues..."
        @input="onInput" />
    </div>
    <div class="clearfix prepend-top-10">
      <button class="btn btn-new pull-left">
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

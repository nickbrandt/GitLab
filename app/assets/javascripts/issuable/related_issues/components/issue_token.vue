<script>
export default {
  name: 'IssueToken',

  props: {
    reference: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    path: {
      type: String,
      required: false,
      default: null,
    },
    state: {
      type: String,
      required: false,
      default: null,
    },
    canRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    stateIconClass() {
      let iconClass = null;
      if (this.state === 'opened') {
        iconClass = 'issue-token-state-icon-open fa fa-circle-o';
      } else if (this.state === 'closed') {
        iconClass = 'issue-token-state-icon-closed fa fa-minus';
      }

      return iconClass;
    },
    accessibleLabel() {
      return `${this.state} ${this.reference} ${this.title}`;
    },
    removeButtonLabel() {
      return `Remove related issue ${this.reference}`;
    },
  },

  methods: {
    onRemoveRequest() {
      this.$emit('removeRequest');
    },
  },
};
</script>

<template>
  <div class="issue-token">
    <a
      class="issue-token-reference"
      :href="path"
      :aria-label="accessibleLabel">
      <i
        v-if="stateIconClass"
        :class="stateIconClass"
        aria-hidden="true" />
      {{ reference }}
    </a>
    <div class="issue-token-title">
      <a
        v-if="title"
        class="issue-token-title-link"
        :href="path"
        aria-hidden="true"
        tabindex="-1">
        {{ title }}
      </a>
      <button
        v-if="canRemove"
        type="button"
        class="issue-token-remove-button has-tooltip"
        :title="removeButtonLabel"
        @click="onRemoveRequest">
        <i class="fa fa-times" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>

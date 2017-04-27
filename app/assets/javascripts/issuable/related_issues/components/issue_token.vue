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
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    state: {
      type: String,
      required: false,
      default: null,
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
  },
};
</script>

<template>
  <div class="issue-token">
    <a
      class="issue-token-reference"
      :href="path">
      <i
        v-if="stateIconClass"
        :class="stateIconClass"
        :aria-label="accessibleLabel" />
      {{ reference }}
    </a>
    <div class="issue-token-title">
      <a
        class="issue-token-title-link"
        :href="path"
        aria-hidden="true"
        tabindex="-1">
        {{ title }}
      </a>
      <button
        class="issue-token-remove-button has-tooltip"
        :title="removeButtonLabel">
        <i class="fa fa-times" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>

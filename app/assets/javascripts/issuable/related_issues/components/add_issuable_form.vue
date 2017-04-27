<script>
export default {
  name: 'AddIssuableForm',

  props: {
    addButtonLabel: {
      type: String,
      required: true,
    },
  },

  methods: {
  },
};
</script>

<template>
  <div>
    <div class="add-issuable-form-input-wrapper form-control">
      <ul class="add-issuable-form-input-token-list">
        <li>some token</li>
      </ul>
      <input
        type="text"
        class="add-issuable-form-input"
        value="asdf"
        placeholder="Search issues..."
        @input="onInput" />
    </div>
    <div class="clearfix prepend-top-10">
      <button class="btn btn-new pull-left">
        {{ addButtonLabel }}
      </button>
      <button class="btn btn-default pull-right">
        Cancel
      </button>
    </div>
  </div>
</template>

<script>
import { GlButton } from '@gitlab/ui';

import Icon from '~/vue_shared/components/icon.vue';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  components: {
    GlButton,
    Icon,
  },
  directives: {
    autofocusonshow,
  },
  data() {
    return {
      query: '',
    };
  },
  methods: {
    handleKeyUp() {
      this.$emit('onSearchInput', this.query);
    },
    handleInputClear() {
      this.query = '';
      this.handleKeyUp();
    },
  },
};
</script>

<template>
  <div :class="{ 'has-value': query }" class="dropdown-input">
    <input
      v-model.trim="query"
      v-autofocusonshow
      :placeholder="__('Search')"
      autocomplete="off"
      class="dropdown-input-field"
      type="search"
      @keyup="handleKeyUp"
    />
    <icon v-show="!query" name="search" />
    <gl-button
      variant="link"
      class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
      data-hidden="true"
      @click.stop="handleInputClear"
    />
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import inputFocus from '../../mixins';

export default {
  components: {
    Icon,
  },
  mixins: [inputFocus],
  computed: {
    ...mapState(['inputValue', 'projectTokens']),
    localInputValue: {
      get() {
        return this.inputValue;
      },
      set(newValue) {
        this.setInputValue(newValue);
      },
    },
  },
  methods: {
    ...mapActions(['setInputValue', 'removeProjectTokenAt']),
    focusInput() {
      this.$refs.input.focus();
    },
  },
};
</script>

<template>
  <div
    :class="{ focus: isInputFocused }"
    class="form-control tokenized-input-wrapper d-flex flex-wrap align-items-center"
    @click="focusInput"
  >
    <div v-for="(token, index) in projectTokens" :key="token.id" class="d-flex" @click.stop>
      <div class="js-input-token input-token text-secondary py-0 pl-2 pr-1 rounded-left">
        {{ token.name_with_namespace }}
      </div>
      <div
        class="js-token-remove tokenized-input-token-remove d-flex align-items-center text-secondary py-0 px-1 rounded-right"
        @click="removeProjectTokenAt(index)"
      >
        <icon name="close" />
      </div>
    </div>
    <div class="d-flex align-items-center flex-grow-1">
      <input
        ref="input"
        v-model="localInputValue"
        :placeholder="__('Search your projects')"
        class="tokenized-input flex-grow-1"
        type="text"
        @focus="onFocus"
        @blur="onBlur"
      />
      <icon name="search" class="text-secondary" />
    </div>
  </div>
</template>

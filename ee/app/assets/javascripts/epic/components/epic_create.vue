<script>
import { mapState, mapActions } from 'vuex';

import { __ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

export default {
  components: {
    LoadingButton,
  },
  props: {
    alignRight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['newEpicTitle', 'epicCreateInProgress']),
    buttonLabel() {
      return this.epicCreateInProgress ? __('Creating epic') : __('Create epic');
    },
    isEpicCreateDisabled() {
      return !this.newEpicTitle.length;
    },
    epicTitle: {
      set(value) {
        this.setEpicCreateTitle({
          newEpicTitle: value,
        });
      },
      get() {
        return this.newEpicTitle;
      },
    },
  },
  methods: {
    ...mapActions(['setEpicCreateTitle', 'createEpic']),
    focusInput() {
      this.$nextTick(() => this.$refs.epicTitleInput.focus());
    },
  },
};
</script>

<template>
  <div class="dropdown epic-create-dropdown">
    <button
      class="btn btn-success qa-new-epic-button"
      type="button"
      data-toggle="dropdown"
      @click="focusInput"
    >
      {{ __('New epic') }}
    </button>
    <div :class="{ 'dropdown-menu-right': alignRight }" class="dropdown-menu">
      <input
        ref="epicTitleInput"
        v-model="epicTitle"
        :disabled="epicCreateInProgress"
        :placeholder="__('Title')"
        type="text"
        class="form-control qa-epic-title"
        @keyup.enter.exact="createEpic"
      />
      <loading-button
        :disabled="isEpicCreateDisabled"
        :loading="epicCreateInProgress"
        :label="buttonLabel"
        container-class="btn btn-success btn-inverted prepend-top-10 qa-create-epic-button"
        @click.stop="createEpic"
      />
    </div>
  </div>
</template>

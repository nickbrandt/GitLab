<script>
import { mapState } from 'vuex';
import { GlFormCheckbox } from '@gitlab/ui';
import store from '~/boards/stores';

export default {
  store,
  components: {
    GlFormCheckbox,
  },
  data() {
    return {
      options: {},
    };
  },
  computed: {
    ...mapState(['configurationOptions']),
  },
  created() {
    this.options = { ...this.configurationOptions };
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <label class="form-section-title label-bold media-body">
      {{ __('Board configuration options') }}
    </label>

    <gl-form-checkbox v-model="options.hideOpenList" data-testid="hide-open-list">
      {{ __('Hide the Open list') }}
    </gl-form-checkbox>

    <gl-form-checkbox v-model="options.hideClosedList" data-testid="hide-closed-list">
      {{ __('Hide the Closed list') }}
    </gl-form-checkbox>
  </div>
</template>

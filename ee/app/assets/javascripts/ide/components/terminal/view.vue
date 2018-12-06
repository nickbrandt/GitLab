<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import EmptyState from './empty_state.vue';

export default {
  components: {
    EmptyState,
  },
  computed: {
    ...mapState('terminal', ['isShowSplash', 'paths']),
    ...mapGetters('terminal', ['allCheck']),
  },
  methods: {
    ...mapActions('terminal', ['hideSplash']),
    start() {
      this.hideSplash();
    },
  },
};
</script>

<template>
  <div class="h-100">
    <div v-if="isShowSplash" class="h-100 d-flex flex-column justify-content-center">
      <empty-state
        :is-loading="allCheck.isLoading"
        :is-valid="allCheck.isValid"
        :message="allCheck.message"
        :help-path="paths.webTerminalHelpPath"
        :illustration-path="paths.webTerminalSvgPath"
        @start="start();"
      />
    </div>
    <template v-else>
      <h5>{{ __('Web Terminal') }}</h5>
    </template>
  </div>
</template>

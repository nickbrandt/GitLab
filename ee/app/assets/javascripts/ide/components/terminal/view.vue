<script>
import { mapState } from 'vuex';
import EmptyState from './empty_state.vue';

export default {
  components: {
    EmptyState,
  },
  computed: {
    ...mapState(['emptyStateSvgPath']),
  },
};
</script>

<template>
  <div class="h-100">
    <div class="h-100 d-flex flex-column justify-content-center">
      <empty-state :illustration-path="emptyStateSvgPath" />
    </div>
  </div>
</template>

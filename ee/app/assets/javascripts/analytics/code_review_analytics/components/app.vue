<script>
import { mapActions } from 'vuex';

export default {
  props: {
    projectId: {
      type: Number,
      required: true,
    },
  },
  created() {
    this.setProjectId(this.projectId);
  },
  methods: {
    ...mapActions(['setProjectId']),
  },
};
</script>

<template>
  <div class="mt-2">
    <div>
      <span class="font-weight-bold">{{ __('Merge Requests in Review') }}</span>
    </div>
  </div>
</template>

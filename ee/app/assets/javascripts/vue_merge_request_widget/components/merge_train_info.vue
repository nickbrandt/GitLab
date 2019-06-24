<script>
import { s__, sprintf } from '~/locale';

export default {
  name: 'MergeTrainInfo',
  props: {
    mergeTrainIndex: {
      type: Number,
      required: true,
    },
  },
  computed: {
    message() {
      return sprintf(s__('mrWidget|Added to the merge train at position %{mergeTrainPosition}'), {
        mergeTrainPosition: this.mergeTrainIndex + 1,
      });
    },
  },
};
</script>

<template>
  <div class="pt-2 pb-2 pl-3 plr-3 merge-train-info">
    <div class="media-body">
      {{ message }}
    </div>
  </div>
</template>

<script>
import { GlButton } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    totalSize: {
      type: Number,
      required: true,
    },
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.totalSize);
    },
  },
  methods: {
    uploadCorpus() {
      /* eslint-disable no-alert */
      alert(s__('CorpusManagement|New corpus'));
    },
  },
};
</script>
<template>
  <div
    class="gl-h-11 gl-bg-gray-10 gl-display-flex gl-justify-content-space-between gl-align-items-center"
  >
    <div class="gl-ml-5">
      {{ s__('CorpusManagement|Total Size:') }}
      <span class="gl-font-weight-bold">{{ formattedFileSize }}</span>
    </div>

    <gl-button class="gl-mr-5" variant="success" @click="uploadCorpus">
      {{ s__('CorpusManagement|New corpus') }}
    </gl-button>
  </div>
</template>

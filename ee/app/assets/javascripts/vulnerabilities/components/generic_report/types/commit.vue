<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  inject: ['commitPathTemplate'],
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    commitPath() {
      // search for all occurences of "$COMMIT_SHA" within the given template, eg.: "/base/project/path/-/commit/$COMMIT_SHA"
      const allCommitShaPlaceHolders = /\$COMMIT_SHA/g;
      // Replace it with the actual commit hash
      // NOTE: This can be swapped to using `replaceAll` once it's more widely supported
      return this.commitPathTemplate.replace(allCommitShaPlaceHolders, this.value);
    },
  },
};
</script>

<template>
  <gl-link :href="commitPath">{{ value }}</gl-link>
</template>

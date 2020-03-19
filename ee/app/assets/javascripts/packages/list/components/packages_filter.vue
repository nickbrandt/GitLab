<script>
import { GlSearchBoxByClick } from '@gitlab/ui';
import { mapActions } from 'vuex';

export default {
  components: {
    GlSearchBoxByClick,
  },
  methods: {
    ...mapActions(['setFilter']),
    onInput(query) {
      this.setFilter(query);
    },
    onSubmit() {
      this.$emit('filter');
    },
  },
};
</script>

<template>
  <gl-search-box-by-click
    :placeholder="s__('PackageRegistry|Filter by name')"
    @submit="onSubmit"
    @input="onInput"
  />
</template>

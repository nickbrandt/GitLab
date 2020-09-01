<script>
import CodeBlock from '~/vue_shared/components/code_block.vue';

export default {
  name: 'ReportItemCode',
  components: {
    CodeBlock,
  },
  props: {
    code: {
      type: String,
      required: true,
    },
    maxHeight: {
      type: String,
      default: '225px',
      required: false,
    },
  },
  computed: {
    styleObject() {
      const { maxHeight } = this;
      const isScrollable = maxHeight !== 'initial';
      const scrollableStyles = {
        maxHeight,
        overflowY: 'auto',
      };

      return isScrollable ? scrollableStyles : null;
    },
  },
};
</script>
<template>
  <code-block :code="code" />
</template>

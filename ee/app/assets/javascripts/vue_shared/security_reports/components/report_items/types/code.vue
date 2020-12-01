<script>
import CodeBlock from '~/vue_shared/components/code_block.vue';

export default {
  name: 'ReportItemCode',
  components: {
    CodeBlock,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    maxHeight: {
      type: String,
      default: '300px',
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
  userColorScheme: window.gon.user_color_scheme,
};
</script>
<template>
  <pre
    class="code d-block m-0"
    :class="$options.userColorScheme"
  ><code :style="styleObject">{{value}}</code></pre>
</template>
